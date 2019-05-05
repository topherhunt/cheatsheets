# Charting


## Architecture

Jupyter lets you press tab to autocomplete functions - useful reference.

Use the `%matplotlib notebook` iPython magic to enable MPL in Jupyter.
(This configures MPL's backend to render charts into the notebook.)

matplotlib architecture:
- **backend** - we use the `notebook` inline backend for rendering. Other backends let you export to svg / png, or export to an interactive format.
- **artists** - classes & objects representing the figures, primitive shapes, and collections of shapes being drawn
- **scripting** layer - gives you a compact syntax for building out charts quickly. We'll use the `pyplot` scripting layer.

pyplot is procedural (we give it step-by-step instructions on what to render) as opposed to declarative (eg. HTML, which defines the structure of what should be rendered).

Simple pyplot example (way briefer than the more OO-standard alternative):

```py
  import matplotlib.pyplot as plt
  import numpy as np

  x = np.random.randn(10000)
  plt.hist(x, 100)
  plt.title(r'Normal distribution with $\mu=0, \sigma=1$')
  plt.savefig('matplotlib_histogram.png')
  plt.show()
```

https://matplotlib.org/api/_as_gen/matplotlib.pyplot.html#module-matplotlib.pyplot

