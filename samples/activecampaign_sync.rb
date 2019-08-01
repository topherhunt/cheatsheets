# These four service classes are the core of a solution I developed to run a daily 2-way
# sync between a growing database of contacts and a 3rd-party CRM (ActiveCampaign).
# Each service class wraps its high-level logic in a public `#call` method, which calls
# out to private methods (or invokes another service) to handle the details.
#
module Services
  module ActiveCampaign
    class SyncPerson
      include Services::Concerns::Callable

      def initialize(actor:, person:, memoized_tag_helper:)
        @actor = actor
        @person = person
        @tag_helper = memoized_tag_helper # this lets us re-use the cached org data
      end

      def call
        return if should_skip_this_person?

        contact_mapping = FindOrAdoptOrCreateContact.call(
          actor: @actor,
          person: @person)
        SyncContactListStatus.call(
          actor: @actor,
          contact_mapping: contact_mapping,
          expected_status: expected_list_status)
        SyncContactTags.call(
          actor: @actor,
          contact_mapping: contact_mapping,
          expected_tag_ids: expected_tag_ids)
        ensure_not_deactivated(contact_mapping)
      rescue => e
        handle_error(e)
      end

      private

      def should_skip_this_person?
        if @person.skip_active_campaign_sync?
          logger.warn("Person #{@person.id} was flagged skip_active_campaign_sync. Skipping.")
          true
        else
          false
        end
      end

      def expected_list_status
        ActiveCampaignListHelper.expected_status(@person)
      end

      def expected_tag_ids
        @tag_helper.expected_tag_ids(@person)
      end

      # In case this person was previously marked as deactivated, but has
      # become active again (which should be pretty rare)
      def ensure_not_deactivated(contact_mapping)
        if contact_mapping.deactivated?
          contact_mapping.update!(deactivated: false)
          logger.warn "Reactivated #{contact_mapping.summarize}"
          # The :deactivated tag has already been removed by SyncContactTags
        end
      end

      def handle_error(e)
        if e.to_s.include?('email_invalid')
          logger.warn("Person #{@person.id} has invalid email (#{@person.email}). Skipping.")
          @person.update!(skip_active_campaign_sync: true)
        elsif e.to_s.include?('PG::UniqueViolation')
          raise "Sync failed with a unique key violation. This is fine if the sync "\
            "somehow ran twice at once (ie. if the ActiveCampaignContactMapping "\
            "cache is being rebuilt), otherwise it's a bug. The exception: #{e}"
        else
          raise e
        end
      end

      def logger
        @logger ||= MyApp::PrefixLogger.new(Rails.logger, "#{self.class}")
      end
    end
  end
end








# Service class to ensure the given person is connected to an ActiveCampaign contact.
#
module Services
  module ActiveCampaign
    class FindOrAdoptOrCreateContact
      include Services::Concerns::Callable

      def initialize(actor:, person:)
        @actor = actor
        @person = person
      end

      def call
        # We assume that mapped ActiveCampaign contacts won't be deleted.
        @person.active_campaign_contact_mapping ||
          adopt_existing_contact ||
          create_and_map_new_contact
      end

      private

      #
      # Adopting an existing contact
      #

      def adopt_existing_contact
        contact_id = find_contact_by_email or return nil
        set_initial_newsletter_preferences_if_nil(contact_id: contact_id)
        set_synced_list_status(contact_id, expected_list_status)
        tag_ids = get_relevant_tag_ids(contact_id)
        # Ensure any conflicting old mapping is removed first
        ActiveCampaignContactMapping.where(contact_id: contact_id).delete_all
        contact_mapping = ActiveCampaignContactMapping.create!(
          person_id: @person.id,
          contact_id: contact_id,
          list_status: expected_list_status,
          tag_ids: tag_ids)
        logger.info "Adopted existing contact for #{contact_mapping.summarize}."
        contact_mapping
      end

      def find_contact_by_email
        response_hash = api_wrapper.get('/api/3/contacts', params: {email: @person.email})
        contact_hash = response_hash.fetch('contacts').first
        contact_hash&.fetch('id')
      end

      # When a person is already in the AC database, their default newsletter
      # preferences should be as follows:
      # - Product news: checked if they haven't unsubscribed from any list
      # - Company news: checked if a) they haven't unsubscribed from any lists and
      #                       b) they're subscribed to the (old) company news list.
      # Notes:
      # - This logic is mostly relevant during the initial sync. Once all pre-existing
      #   contacts have been synced to AC, this will mostly become irrelevant.
      # - When checking for any unsubscribes, we ignore the "Synced" list itself
      #   to avoid circular causality in certain edge cases. We only care about
      #   their status on lists that predated the sync script.
      def set_initial_newsletter_preferences_if_nil(contact_id:)
        contact_lists = get_contact_lists(contact_id: contact_id)
        has_no_unsubscribes = contact_lists.all?(&:subscribed?)
        on_company_news_list = contact_lists.any? { |cl| cl.list_id == company_news_list_id }
        update_preferences_only_if_nil(
          wants_product_newsletter: has_no_unsubscribes,
          wants_company_newsletter: has_no_unsubscribes && on_company_news_list,
          why: "inferred based on contact #{contact_id}'s list status")
      end

      def get_contact_lists(contact_id:)
        response = api_wrapper.get("/api/3/contacts/#{contact_id}/contactLists")
        response.fetch('contactLists')
          .map { |hash| ActiveCampaignContactListWrapper.new(hash) }
          .reject(&:list_is_the_synced_list?)
      end

      def company_news_list_id
        ActiveCampaignListHelper::company_NEWS_LIST_ID
      end

      def get_relevant_tag_ids(contact_id)
        api_wrapper.get("/api/3/contacts/#{contact_id}/contactTags")
          .fetch('contactTags')
          .map { |hash| ActiveCampaignContactTagWrapper.new(hash) }
          .select(&:relevant?)
          .map(&:tag_id)
      end

      #
      # Creating a Contact
      #

      def create_and_map_new_contact
        contact_id = create_contact
        set_default_newsletter_preferences
        set_synced_list_status(contact_id, expected_list_status)
        contact_mapping = ActiveCampaignContactMapping.create!(
          person_id: @person.id,
          contact_id: contact_id,
          list_status: expected_list_status,
          tag_ids: [])
        logger.info "Created new contact for #{contact_mapping.summarize}."
        contact_mapping
      end

      def create_contact
        name = MyApp::PersonName.new(@person.name)
        response = api_wrapper.post('/api/3/contacts', body: {
          contact: {
            email: @person.email,
            firstName: name.first || name.full,
            lastName: name.last
          }
        })
        response.fetch('contact').fetch('id')
      end

      def set_default_newsletter_preferences
        update_preferences_only_if_nil(
          wants_product_newsletter: true,
          wants_company_newsletter: false,
          why: 'default settings for new contact')
      end

      #
      # Low-level
      #

      # It's possible that a person's newsletter preferences have already been
      # set. If so, we definitely don't want to override the current settings.
      # e.g. if we cleared out & repopulated the mappings for some reason.
      def update_preferences_only_if_nil(wants_product_newsletter:, wants_company_newsletter:, why:)
        ActiveCampaignPersonHelper.update_preferences_only_if_nil(
          person: @person,
          wants_product_newsletter: wants_product_newsletter,
          wants_company_newsletter: wants_company_newsletter,
          why: why)
      end

      def set_synced_list_status(contact_id, status)
        ActiveCampaignListHelper.set_synced_list_status(contact_id, status)
      end

      def expected_list_status
        ActiveCampaignListHelper.expected_status(@person)
      end

      def api_wrapper
        ActiveCampaignApiWrapper
      end

      def logger
        @logger ||= MyApp::PrefixLogger.new(Rails.logger, "#{self.class}")
      end
    end
  end
end











module Services
  module ActiveCampaign
    class SyncContactListStatus
      include Services::Concerns::Callable

      def initialize(actor:, contact_mapping:, expected_status:)
        @actor = actor
        @contact_mapping = contact_mapping
        @expected_status = expected_status
      end

      def call
        if current_status != @expected_status
          logger.info "#{@contact_mapping.summarize}: Updating list status to #{@expected_status}."
          set_synced_list_status(contact_id, @expected_status)
          @contact_mapping.update!(list_status: @expected_status)
        end
      end

      private

      def current_status
        @contact_mapping.list_status
      end

      def contact_id
        @contact_mapping.contact_id
      end

      def set_synced_list_status(contact_id, status)
        ActiveCampaignListHelper.set_synced_list_status(contact_id, status)
      end

      def logger
        @logger ||= MyApp::PrefixLogger.new(Rails.logger, "#{self.class}")
      end
    end
  end
end









module Services
  module ActiveCampaign
    class SyncContactTags
      include Services::Concerns::Callable

      def initialize(actor:, contact_mapping:, expected_tag_ids:)
        @actor = actor
        @contact_mapping = contact_mapping
        @current_tag_ids = @contact_mapping.tag_ids
        @expected_tag_ids = expected_tag_ids # we expect this to be an array of strings
      end

      def call
        if @current_tag_ids.sort != @expected_tag_ids.sort
          log_my_intentions
          to_apply.each { |tag_id| tag_helper.apply_tag(contact_id, tag_id) }
          to_remove.each { |tag_id| remove_tag(tag_id) }
          @contact_mapping.update!(tag_ids: @expected_tag_ids)
        end
      end

      private

      def to_apply
        @expected_tag_ids - @current_tag_ids
      end

      def to_remove
        @current_tag_ids - @expected_tag_ids
      end

      def log_my_intentions
        logger.info "#{@contact_mapping.summarize}: Updating tags. "\
          "(current: #{@current_tag_ids.map(&:to_i)}, "\
          "add: #{to_apply.map(&:to_i)}, "\
          "remove: #{to_remove.map(&:to_i)})"
      end

      def remove_tag(tag_id)
        # You can't remove a tag from a Contact by referencing the tag id.
        # You need to get the corresponding ContactTag association's id.
        if contact_tag = all_contact_tags.find { |ct| ct.tag_id == tag_id.to_s }
          api_wrapper.delete("/api/3/contactTags/#{contact_tag.id}")
        else
          logger.warn "Can't remove tag #{tag_id} from #{@contact_mapping.summarize}; "\
            "that ContactTag association isn't found. Skipping."
          # This MIGHT mean that a previously-relevant tag (whose id is stored on
          # the cached contact mapping) was deleted. The ContactTags results omit
          # CT associations for nonexistent tags.
        end
      end

      def all_contact_tags
        @all_contact_tags ||= api_wrapper.get("/api/3/contacts/#{contact_id}/contactTags")
          .fetch('contactTags')
          .map { |hash| ActiveCampaignContactTagWrapper.new(hash) }
      end

      def contact_id
        @contact_mapping.contact_id
      end

      def tag_helper
        @tag_helper ||= ActiveCampaignTagHelper.new
      end

      def api_wrapper
        ActiveCampaignApiWrapper
      end

      def logger
        @logger ||= MyApp::PrefixLogger.new(Rails.logger, "#{self.class}")
      end
    end
  end
end

