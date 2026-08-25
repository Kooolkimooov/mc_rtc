#
# Copyright 2015-2020 CNRS-UM LIRMM, CNRS-AIST JRL
#

cimport mc_rtc.c_mc_rtc as c_mc_rtc

from libcpp cimport bool as cppbool
from libcpp.string cimport string

cdef class Logger(object):
  cdef c_mc_rtc.Logger * impl

cdef Logger LoggerFromRef(c_mc_rtc.Logger &)

cdef class Configuration(object):
  cdef c_mc_rtc.Configuration * impl
  cdef cppbool own_impl__

cdef Configuration ConfigurationFromValue(c_mc_rtc.Configuration)
cdef Configuration ConfigurationFromRef(c_mc_rtc.Configuration &)

cdef class DataStore(object):
  cdef c_mc_rtc.DataStore * impl
  # True when impl was allocated here, False when it points at a datastore owned
  # by C++ (e.g. a controller's)
  cdef cppbool own_impl__

  cdef object _tag(self, string key)
  cdef object _get(self, string key, t)
  cdef object _call_get(self, string key, t, cppbool const_ref)
  cdef void _call_set(self, string key, t, value, cppbool const_ref) except *
  cdef void _set(self, string key, t, value, cppbool create) except *

cdef DataStore DataStoreFromRef(c_mc_rtc.DataStore &)
