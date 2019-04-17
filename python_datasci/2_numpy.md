# Numpy

Basic working with arrays:

- Convert a list into a numpy array: `a = numpy.array(some_list)`. You can also provide a list of lists to create a multidimensional array.
- `array.shape` tells you the dimensions of the Array (ie. how nested?)
- `arange(start, stop, step_size)` returns evenly-spaced values within that range
- use `array.reshape(3, 5)` to change the shape of an array -- e.g. convert a 1d array to a 2d or 3d array. `.resize` seems similar.
- `numpy.ones(3, 10)` returns a multidimensional array where each item is 1.
- `numpy.zeros(3, 10)` - same with zeros
- `numpy.diag([1, 2, 3, 4])` - return a 2d array with zeros for most cells and each item making a diagonal line down the matrix.
- You can combine multiple arrays together e.g. with `numpy.vstack(a1, a2)` which stacks two 2d arrays together. Or `numpy.hstack` which stacks them horizontally.
- You can use basic arithmetic like `+`, `*`, and `**` (power) on arrays. You can pass it either a number or an array of numbers (whose shape must be compatible).
- Transpose a 2d array using the T method: `array.T`
- See the data type in an array: `array.dtype`
- Cast an array to a different type: `array.astype('f')`
- Some convenience methods on array: `a.sum()`, `a.max()`, `a.min()`, `a.mean()`, `a.std()`, `a.argmax()` (get the index of the max value) and `a.argmin()` (same)

Slicing & transformation:

- As with lists, you can use bracket & colon notation to get a particular item or slice from an array.
- You can also reverse the ordering of a slice and/or specify the step size with `::` like this: `array[5::-2]` will start with the 5th element and take every *second* element back to the beginning of the array.
- You can reach into multidimensional arrays using a shorthand comma notation: `array[3, 1]` grabs a slice of the 2d array, but preserves the original # of dimensions. (ie. it's different from `array[3][1]`.) And `array[-1, ::3]` means "select every 3rd element from the last row".
- You can use simple operators in bracket notation to conditionally select items: `r[r < 30]`. (This will collapse multidimensional arrays). You can even combine this with assignment to max out certain values, e.g.: `array[array < 30] = 30`
- Set all items of an array: `array[:] = 0`
- **Careful:** When you take a slice of an array, it uses a shared reference to those elements of the original array. So you can subslice an array, nil out or transform the values, and the original full array will reflect that change. Use `array.copy()` to dup an array to protect against accidental mutations of shared references.

Iterating over arrays:

- Iterate over an array using the `for` syntax: `for row in array:`
- Get both the index and the item: `for i, row in enumerate(array): ...`
- Iterate over two arrays together: `for i, j in zip(array1, array2):`
