//
//	Maude's internal vector
//

%{
#include <vector.hh>
%}

// Since the iterator defined by Python in the presence of __getitem__
// and __len__ does not stop, VectorIterator is defined to substitute it
#if defined(SWIGPYTHON)
%pythoncode %{
class VectorIterator:
	def __init__(self, vect, length):
		self.vect = vect
		self.i = 0
		self.length = length

	def __iter__(self):
		return self

	def __next__(self):
		if self.i >= self.length:
			raise StopIteration
		self.i = self.i + 1
		return self.vect[self.i - 1]
%}
#endif

/**
 * Internal Maude vector.
 */
template<class _Tp>
class Vector {
public:
	typedef _Tp value_type;
	typedef value_type* pointer;
	typedef const value_type* const_pointer;
	typedef value_type& reference;
	typedef const value_type& const_reference;
	typedef size_t size_type;
	typedef ptrdiff_t difference_type;

	/**
	 * Construct a vector.
	 *
	 * @param length The initial length.
	 */
	Vector(size_type length = 0);
	/**
	 * Is the vector empty?
	 */
	bool empty() const;
	/**
	 * Size of the vector.
	 */
	size_type size() const;
	/**
	 * Reserved capacity of the vector.
	 */
	size_type capacity() const;

	/**
	 * Swap this vector's contents with another.
	 *
	 * @param other The other vector.
	 */
	void swap(Vector& other);

	%extend {
		_Tp __getitem__(size_type n) const {
			return (*$self)[n];
		}

		void __setitem(size_type n, _Tp value) {
			(*$self)[n] = value;
		}

		size_type __len__() const {
			return $self->size();
		}
	}

	%rename (__append) append;
	void append(const _Tp& item);

	// __setitem__ and append disassociate the Python object from the
	// underlying C++ object, since the latter must survive in the vector
	#if defined(SWIGPYTHON)
	%pythoncode %{
		def __setitem__(self, n, v):
			v.thisown = 0
			self.__setitem(n, v)

		def __iter__(self):
			return VectorIterator(self, len(self))

		def __repr__(self):
			return '{} with {} elements'.format(type(self).__name__, len(self))

		def __str__(self):
			if len(self) == 0:
				return 'empty'

			vector_str = str(self[0])
			for i in range(1, len(self)):
				vector_str = vector_str + ', ' + str(self[i])

			return vector_str

		def append(self, v):
			v.thisown = 0
			self.__append(v)
	%}
	#endif

	/**
	 * Set the vector length to zero.
	 */
	void clear();

	/**
	 * Resize the vector.
	 *
	 * @param new_size New size.
	 */
	void resize(size_type new_size);
};
