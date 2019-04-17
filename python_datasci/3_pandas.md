# Pandas


## Series

- Series is a 1D data structure in pandas. It's like a cross btw a list and a dict. Items are ordered, and can be accessed via index or string/object key. The same key can exist multiple times.
- Allows much faster data processing than normal python lists.
- Has some magical handling of None values, so be careful. e.g. when the series is a list of numbers, it converts None to NaN, which makes equivalence testing tricky.

Create a numeric-indexed series by giving it a list of values:

    pandas.Series(['Tiger', 'Bear', 'Moose'])

Or create a string-indexed series by providing a dict:

    pandas.Series({'Topher': 'dinosaurs', 'Lily': 'ducks'})

Or create a string-indexed series by providing two lists:
(**Note**: the same key can show up multiple times, keys aren't unique!)

    pandas.Series(['dinosaurs', 'ducks', 'pokemon'], index=['Topher', 'Lily', 'Topher'])

Give a series a name to make it a bit more self-explanatory:

    series.name = 'Average GDP per country'

You can slice a series like a list:

    series[0:3]

Get the length of a series:

    len(series)

You can query a series either by index position or by key.

Get an entry by index:

    series.iloc[3] # the 4th record (works even if the series has string keys)
    series[3] # shorthand syntax (when the index is a number)

Get an entry by string key:

    series.loc['Sumo'] # => the value associated with "Sumo"
    series['Sumo'] # shorthand syntax (when the index is a string / object)

**Warning**: If multiple entries match your query, you'll get a new Series back rather than just the value. So in some cases `loc` will return a value and in other cases it will return a Series. Check the value using `type(result)`.

You can also use `.loc` and `.iloc` to add or modify values in-place.

You can iterate over all items in a series using `for`, but it's usually faster to use vectorization functions like `numpy.sum` which take an iterable and use parallel computing to speed up processing. If you're looping over a series, you should question whether there's a more efficient (or more idiomatic) way to do it.

Vector example of summing all items in a series:

    import numpy
    total = numpy.sum(series) # a vector function
    total

**Broadcasting** lets you apply an operation to every value in a series, e.g. simple arithmetic. Again this "cleverer" vector approach is way way faster than the standard `for` approach.

    series += 2 # adds 2 to each number in the series

Append two serieses together:
(**Note**: This returns a new series as opposed to mutating series1 in-place.)

    all_countries = series1.append(series2)


## DataFrames

- DataFrames are the heart of the pandas library, much more commonly used than Series. It's a 2D data structure, like a sql table. Like a Series, a record in a DF can be retrieved using either `iloc` or `loc`.
- You can easily fetch all values in a given row, or all values in a given column.
- Both row and column labels can be non-unique.
- Many operations on a DF return a *view* rather than returning a new DF. Remember that if you make changes to a view, it will mutate the original DF. Some operations (eg. `.drop(col)`) instead return a new DF and won't mutate the original. If you don't want to mutate the original, consider calling `df.copy()` first, then operating on the copy.

Create a DF from a list of Serieses (one for each row) and a dict of labels:
(or you can just pass a list of Serieses which will be num-indexed)

    s1 = pandas.Series({'cuisine': 'Chinese', 'animal': 'Dinosaurs'})
    s2 = pandas.Series({'cuisine': 'Vietnamese', 'animal': 'Ducks'})
    s3 = pandas.Series({'cuisine': 'Italian', 'animal': 'Pokemon'})
    df = pandas.DataFrame({'Topher': s1, 'Lily': s2, 'David': s3})

You can also create it from a dict of dicts, or a dict of lists (specifying the column names using `index=`).

Get a row from a DF using `iloc` or `loc`:
(If there's only 1 row, this returns a Series. Otherwise it returns a DF.)

    df.loc['Lily']
    df.iloc[1]

Slice by index:

    df.iloc[1:4]

Get values for specific rows for one column:

    df.loc[['Topher', 'David'], 'animal']

Get all rows, specific columns:

    df.loc[:, ['cuisine', 'animal']]

You can also use this shorthand for getting all values for a col (avoid this):

    df['cuisine'].values

Get a specific value for a specific record:
(returns the value if only 1 result, or a DF if there's multiple results

    df.loc['Topher', 'animal']

Loop over each row in a dataframe:

    for index, row in df.iterrows():
      print(row)

Loop over **and add / modify data in** each row of a dataframe:
(TODO: There should also be a more functional way to do this using df.apply or something, but I haven't figured it out yet)

    # First you should initialize any new columns, for hygiene
    states_df['NUM_COUNTIES'] = None
    for index, row in states_df.iterrows():
      state_name = row['STNAME']
      num_counties = len(counties[ counties['STNAME'] == state_name ])
      states_df.loc[index, 'NUM_COUNTIES'] = num_counties

Transpose the DF:

    df.T

Don't chain indexing operations. e.g. `df['Topher']['animal']`, this leads to hard-to-predict results (eg. returns a copy of the df rather than a view into it)

Drop the matching row(s) from a DF:
(by default this returns a new copy, doesn't mutate the original)

    df.drop('Topher') # returns a new DF, with the remaining rows

Drop the matching column(s) from a DF:

    df.drop('cuisine', axis=1)

Add a new column to a DF:

    df['birth_date'] = None # None = all rows' default value for that col

Update all values in a column in the DF:

    df['cost'] *= 0.8 # apply a 20% discount on all rows

Load a csv into a DataFrame:

    df = pandas.read_csv('olympics.csv', index_col=0) # see also .read_csv() opts
    df.head()

You can rename a DF's columns by hard-coding new names:

    df.columns = ['favorite_food', 'favorite_animal']

Or rename a column by specifying the old name:

    df.rename(columns={'cuisine': 'favorite_food'}, inplace=True)

Or rename multiple columns programmatically:
(I'll avoid this)

    for colname in df.columns:
      if colname[:2] == '01':
        df.rename(columns={colname: 'New column name'}, inplace=True)
      # ...

Add a row to a DataFrame by defining a series with the same shape:

    # the index must be specified in the series' `name` attribute
    # (for multi-level indexes, provide a tuple to `name`)
    s = pandas.Series(data={'cuisine': 'French', 'animal': 'Cat'}, name='Madeline')
    df.append(s)

You can also append a DataFrame to another DataFrame:
(make sure they have the same shape and indexes)

    df2 = pandas.DataFrame(...)
    df = df.append(df2) # immutable, returns a new DF


### DataFrames: Querying & filtering

- Boolean masking is really important for df querying. A boolean mask (bitmask) is an array of True/False values that you overlay on a dataframe to select only the entries where the value is True.

Create a bitmask by performing some conditional on a DF column:

    df['num_gold_medals'] > 2
    # => returns a Series of key=row id, value=True/False

And you can apply a bitmask using `.where()`:

    filtered_df = df.where(df['num_gold_medals'] > 2)
    # (This will return the same # of rows, but any filtered-out rows will have NaN for all fields, causing most pandas operations to ignore those rows.)

Then you can drop the filtered-out rows:

    filtered_df.dropna()

There's a shorthand for `where` filtering rows and dropping the nonmatched ones:

    filtered_df = df[ df['num_gold_medals'] > 2 ]

You can also combine bitmask expressions naturally:
(Remember to wrap each bitmask expression in parens!)

    filtered_df = df[ (df['num_gold'] == 0) & (df['num_silver'] == 0) ]


### DataFrames: Indexes

You can change what column is used as the index like this:

    # First, copy the old index into a new column so we don't lose that data
    df['country'] = df.index
    df = df.set_index('num_gold_medals') # returns a NEW index, doesn't mutate!

Or use `.reset_index()` to promote the current index to a column and apply a default numeric index:

    df.reset_index()

You can set a multi-level index if there's 2 "defining" columns for each row:
(Careful, lookups for mult-level indexes are a bit tricky)

    new_df = df.set_index(['STATE_NAME', 'COUNTY_NAME']) # returns a copy!

When fetching a row from a multi-level indexed DF, you need to specify all levels in order:
(I'm pretty sure I want to avoid this as much as possible.)

    df.loc['Michigan', 'Washtenaw County']

If appending a row to a multi-level indexed DF, make sure you use a tuple for the Series name (the DF index):

    s = pd.Series(data={'cost': 3.00, 'item': 'Cat Food'}, name=('Store 2', 'Kevyn'))
    df = df.append(s)


### DataFrames: Missing values

You can use `.fillna()` to fill in null values to make the dataset easier to work with. For example if you have timeseries data, you might want to fill any null values with the value from the previous row. (Make sure it's sorted first!)

Most aggregate dataframe functions will ignore / exclude missing values.


### DataFrames: Sorting

Sort a DF by desired column(s):

    df.sort_values(by=['POPESTIMATE2015'], inplace=True, ascending=False)


### DataFrames: Adding columns & merging DFs

Adding a new column of data to a DF is a bit complex when you don't know values for all rows. One way is to provide an index-keyed Series like this:

    df = df.reset_index() # May need to reset the index to plain integers first
    df['Date'] = pd.Series({0: 'December 1', 2: 'mid-May'})
    # Any unspecified values will be left as None or NaN

Merging two DFs requires some planning:

* Do you want an outer join (include all members of either set)
  or an inner join (only include members of both sets)?
* What fields will you merge on? Conceptually simpler if both DFs have the same index.
* If both DFs have a same-named field with conflicting data in it, pandas will
  populate `field_name_x` and `field_name_y` columns to preserve which values
  came from which original DF.

Do an OUTER merge (union):
(will include all staff and all students)

    pd.merge(staff_df, students_df, how='outer', left_index=True, right_index=True)
    # Will include all rows from both DFs. Rows that were in one DF but not the
    # other, will have NaNs for all columns irrelevant to them.

Do an INNER merge (intersection):

    pd.merge(staff_df, students_df, how='inner', left_index=True, right_index=True)
    # Will include only rows that were present in BOTH tables.

Do a LEFT merge:

    pd.merge(staff_df, students_df, how='left', left_index=True, right_index=True)
    # This will include all staff (regardless of whether they're present in the
    # students_df or not) but will include their student data if present.

Do a RIGHT merge:

    pd.merge(staff_df, students_df, how='right', left_index=True, right_index=True)
    # This will include all rows from students_df. If a student was also present
    # in staff_df, their staff data will also be populated.

Merging multi-indexed DFs:
(just specify a list of fields to use as join keys)

    pd.merge(staff_df, students_df, how='inner', left_on=['First Name', 'Last Name'], right_on=['First Name', 'Last Name'])

If your DFs are multi-indexed, you can specify the list of fields that will be the merge key

## DataFrames: Grouping

Splits a DF into chunks based on one or more distinguishing columns. Returns a DFGroupBy object which can be iterated on.

Using groupby to get the county population avg *per state*:
(This runs wayyy faster than the more vanilla approach, namely looping over each state name and fetching all counties in that state.)

    %%timeit -n 10
    for group, frame in df.groupby('STNAME'):
      avg = np.average(frame['CENSUS2010POP'])
      print('Counties in state ' + group + ' have an average population of ' + str(avg))

You can also pass a function or lambda to groupby, e.g.:

    for group, frame in df.groupby(lambda row: row['long_name'][:2]):
        print('This row was put in group '+str(group)+'.')

Common pattern: SPLIT -> APPLY -> COMBINE

Compute an aggregate value per state using `agg`:

    df.groupby('STATE_NAME').agg({'CENSUS2010POP': np.average})
    # Be CAREFUL using .agg this way. The dict keys are interpreted differently
    # depending on whether it's called on a Series (1 column of data) or a DF
    # (multiple columns of data).

Compute total weight, grouped by category, using `apply`:
(I like this better than .agg so far)

    (df.groupby('Category')
      .apply(lambda df2: numpy.sum(df2['Weight'] * df2['Quantity'])))
      # note that the apply lambda is passed the DF for that group, not a row!


## PANDAS idioms

"pandorable"

Avoid chaining [] index operators. Example (BAD): `df.loc['thing']['thing']`

Use method chaining, e.g.:

    (df.where(df['SUMLEV']==50)
      .dropna()
      .set_index(['STNAME','CTYNAME'])
      .rename(columns={'ESTIMATESBASE2010': 'Estimates Base 2010'}))

Passing a map function to `.apply`:

    import numpy as np
    # Define a function that we'll apply to each row
    def calculate_min_and_max(row):
      data = row[['POPESTIMATE2010',
                  'POPESTIMATE2011',
                  'POPESTIMATE2012',
                  'POPESTIMATE2013',
                  'POPESTIMATE2014',
                  'POPESTIMATE2015']]
      row['max'] = np.max(data)
      row['min'] = np.min(data)
      return row

    # Now apply that function to each row in a DF. (Use axis=1 here because ??)
    df.apply(calculate_min_and_max, axis=1)

But the more pandorable pattern is to pass a lambda to apply:

    columns = ['POPESTIMATE2010', 'POPESTIMATE2011', ...]
    df.apply(lambda row: np.max(row[columns]), axis=1)


## Scales

Pandas lets you specify which scale a given column is using. 4 kinds of scales:

- Ratio scale: fully numeric, units are equally spaced, "0" is a meaningful concept
  eg. height, weight.

- Interval scale: units are equally spaced, but the value "0" is arbitrary,
  so concepts like multiplication & division aren't valid.
  e.g. Celcius temperature or latitude & longitude.

- Ordinal scale: values are ordered / ranked, but not necessarily equally spaced.
  e.g. letter grades.

- Nominal scale: categories with no clear ordering or ranking.
  e.g. sport team names.

Specify that a column's values are on an ordinal scale:

    df['Grades'].astype('category', categories=['D', 'C', 'B', 'A', 'A+'], ordered=True)
    # Then you can use this ordering in bitmasks / filtering:
    df[ df['Grades'] >= 'B' ]

Often it's useful to convert interval/ratio data to ordinal or nominal data, even though doing so loses information, because many charts & analyses work best with coarse buckets (eg. histograms) and ML also loves buckets.

Pandas' `cut` splits a df's rows into N equally-spaced ordered buckets, degrading interval data into ordinal data, like this:

    pd.cut(s, 3, labels=['Small', 'Medium', 'Large'])
    # The labels are optional but make it much easier to read.
    # Will return a new series of each item's index + the bucket window.
    # This guarantees that buckets are equally sized, NOT that they contain equal
    # #s of entries!


## Pivot tables

A pivot table is a DF where the rows represent one var that you're interested in, the columns a second var, and each cell is some aggregate value. (plus marginal values, ie. the sums for each column & row.)

Given a csv of data on each model of electric car, here's how to create a pivot table that shows battery capacity by year and model/make:

    df.pivot_table(values='kW', index='year', columns='make', aggfunc=numpy.mean)
    # You can specify multiple value fields or multiple agg functions too.


## Dates/times

- Timestamp: a specific point in time. Mostly interchangeable w Python's DateTime.

- Period: a specific period in time, e.g. the month "Jan 2016".

- Timedelta: an interval of time (not tied to any particular start time).

- DatetimeIndex and PeriodIndex are just those values when they're the index of a series.

Create a Timestamp from a well-formed string:

    pd.Timestamp('9/1/2016 10:05AM')

Parse many formats of string to a timestamp:

    pd.toDatetime('4.7.12', dayfirst=True)

Create a Period:

    pd.Period('3/5/2016') # the full day of March 5th, 2016

Create a Timedelta by subtracting two Timestamps:

    pd.Timestamp('9/3/2016') - pd.Timestamp('9/1/2016')

Or create a Timedelta from string:

    pd.Timedelta('12D 3H')

You can add / subtract timedeltas to timestamps:

    pd.Timestamp('9/2/2016 8:10AM') + pd.Timedelta('12D 3H')
    # => a new Timestamp('2016-09-14 11:10:00')

Use `pd.date_range` to quickly create a series of timestamps in a pattern:

    # Starting on Sept 30th, list every 2nd Sunday for 9 periods
    dates = pd.date_range('10-01-2016', periods=9, freq='2W-SUN')
    # => DatetimeIndex(['2016-10-02', '2016-10-16', '2016-10-30', '2016-11-13', ...]

Check the day-of-week of a timestamp:

    dt.weekday_name # => 'Wednesday'

You can also do some cool transformations on DateTimeIndexes and PeriodIndexes, e.g. resample to another day of week, regroup by a different frequency, slice the df by dates same as if they were numeric indexes, etc.

matplotlib.pyplot also works great with timeseries axes.


## Correlations, plots

Get the Pearson correlation btw two serieses:

    corr = Top15['Citable docs per Capita'].corr(Top15['Energy Supply per Capita'])

Render a scatter plot of two columns:

    import matplotlib as plt
    %matplotlib inline

    Top15 = answer_one() # a DF of countries' energy and population stats
    Top15['PopEst'] = Top15['Energy Supply'] / Top15['Energy Supply per Capita']
    Top15['Citable docs per Capita'] = Top15['Citable documents'] / Top15['PopEst']
    Top15.plot(x='Citable docs per Capita', y='Energy Supply per Capita', kind='scatter', xlim=[0, 0.0006])

