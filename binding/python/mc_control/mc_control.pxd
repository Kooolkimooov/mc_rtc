#
# Copyright 2015-2019 CNRS-UM LIRMM, CNRS-AIST JRL
#

cimport mc_control.c_mc_control as c_mc_control

from libcpp cimport bool as cppbool

cdef class ControllerResetData(object):
  cdef c_mc_control.ControllerResetData * impl
  # True when impl was allocated here and must be freed; False when it only
  # points at one C++ owns (ControllerResetDataFromPtr, the reset callback).
  cdef cppbool owns_impl

cdef ControllerResetData ControllerResetDataFromPtr(c_mc_control.ControllerResetData *)

cdef class Contact(object):
  cdef c_mc_control.Contact impl

cdef Contact ContactFromC(const c_mc_control.Contact&)

cdef public api class MCController(object)[object MCControllerObject, type MCControllerType]:
  cdef c_mc_control.MCController * base

cdef MCController MCControllerFromPtr(c_mc_control.MCController *)

cdef class PythonRWCallback(object):
  cdef c_mc_control.PythonRWCallback impl

cdef public api class MCPythonController(MCController)[object MCPythonControllerObject, type MCPythonControllerType]:
  cdef c_mc_control.MCPythonController * impl

cdef class MCGlobalController(object):
  cdef c_mc_control.MCGlobalController * impl

cdef class ElementId(object):
  cdef c_mc_control.ElementId impl

cdef class ControllerClient(object):
  cdef c_mc_control.ControllerClient * impl
