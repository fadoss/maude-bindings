//
//	Maude's internal vector
//

%{
#include <vector.hh>
%}

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

	%apply SWIGTYPE *DISOWN {_Tp value};
	%extend {
		/**
		 * Get a vector position value.
		 *
		 * @param n Vector position from zero.
		 */
		_Tp GETTER_METHOD(size_type n) const {
			return (*$self)[n];
		}

		/**
		 * Set a vector position value.
		 *
		 * @param n Vector position from zero.
		 * @param value Value to be set.
		 */
		void SETTER_METHOD(size_type n, _Tp value) {
			(*$self)[n] = value;
		}

		/**
		 * Append a new element to the vector.
		 */
		void append(_Tp value) {
			$self->append(value);
		}
	}
	%clear _Tp value;

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
