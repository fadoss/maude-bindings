//
// C++ functions for converting types to Python (to be inserted in the SWIG source)
//

// Basic types

PyObject* convert2Py(long value) {
	return PyLong_FromLong(value);
}

PyObject* convert2Py(const char* value) {
	return SWIG_FromCharPtrAndSize(value, strlen(value));
}

PyObject* convert2Py(const std::string &value) {
	return SWIG_From_std_string(value);
}

// Types from Maude

PyObject* convert2Py(View* view) {
	return SWIG_NewPointerObj(SWIG_as_voidptr(view), SWIGTYPE_p_View, 0);
}

// Types from the bindings

PyObject* convert2Py(EasyTerm* value) {
	return SWIG_NewPointerObj(SWIG_as_voidptr(value),
		                  SWIGTYPE_p_EasyTerm, SWIG_POINTER_OWN);
}

PyObject* convert2Py(EasySubstitution* value) {
	return SWIG_NewPointerObj(SWIG_as_voidptr(value),
		                  SWIGTYPE_p_EasySubstitution, SWIG_POINTER_OWN);
}

// Structured objects

template<typename T>
PyObject* convert2Py(const std::vector<T>& vector) {
	size_t nrElems = vector.size();
	PyObject* tuple = PyTuple_New(nrElems);

	for (size_t i = 0; i < nrElems; ++i) {
		PyObject* elem = convert2Py(vector[i]);
		PyTuple_SetItem(tuple, i, elem);
	}

	return tuple;
}

template<typename T1, typename T2>
PyObject* convert2Py(const std::pair<T1, T2>& pair) {
	PyObject* first = convert2Py(pair.first);
	PyObject* second = convert2Py(pair.second);

	PyObject* tuple = PyTuple_Pack(2, first, second);

	Py_XDECREF(first);
	Py_XDECREF(second);

	return tuple;
}
