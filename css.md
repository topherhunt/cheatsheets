# CSS styling

My current favorite paradigm is an adaptation of BEM where the block, element, and modifier are composed of different classes.

Basic rules:

  * Block, element, and modifier labels are always camelCased.
  * A block class starts with `b-`, such as `b-codingPageTimeline`.
  * An element class starts with `__`, such as `__tickmark`.
  * A modifier class starts with `--`, such as `--major`.
  * Element styles are always scoped to inside the block, but never to inside other elements. Don't nest elements, i.e. don't make an element's style depend on it being inside versus outside of another element.
  * Modifier styles are always scoped to the block, the element (if relevant), and the status.
  * Block, element, and modifier names are camelCased.

Benefits:

  * Concise, descriptive, readable html markup with no repetition. The css will be similar verbosity to vanilla BEM. You don't end up with redundant classes like `<div class="b-codingPage__timelineTickmark b-codingPage__timelineTickmark--minor"></div>`.
  * Simple contract for how to use classes guarantees isolation. You can be sure that your `__timeline` element class isn't polluted with irrelevant styles, because the convention is that all styles on elements and modifier are scoped to the parent block.
  * Minimizes agony re: picking class names.


## Flexbox

Column A fixed width, column B variable width:

```
.container { display: flex; }
.col-a { flex: 0 0 10rem; }
.col-b { flex: 1 }
```
