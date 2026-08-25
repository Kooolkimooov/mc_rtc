# distutils: language = c++

#
# Copyright 2015-2020 CNRS-UM LIRMM, CNRS-AIST JRL
#

from cython.operator cimport dereference as deref

cimport mc_rtc.c_mc_rtc as c_mc_rtc

cimport mc_rbdyn.mc_rbdyn as mc_rbdyn
cimport mc_control.c_mc_control as c_mc_control
cimport mc_control.mc_control as mc_control

cimport eigen.c_eigen as c_eigen
cimport eigen.eigen as eigen

cimport sva.c_sva as c_sva
cimport sva.sva as sva

from libcpp.vector cimport vector
from libcpp.string cimport string
from libcpp cimport bool as cppbool
from cython.operator cimport dereference as deref

try:
    from collections.abc import Iterable
except ImportError:
    from collections import Iterable
import numbers

MC_ENV_DESCRIPTION_PATH = c_mc_rtc.MC_ENV_DESCRIPTION_PATH
INSTALL_PREFIX = c_mc_rtc.INSTALL_PREFIX
MC_ROBOTS_INSTALL_PREFIX = c_mc_rtc.MC_ROBOTS_INSTALL_PREFIX
MC_CONTROLLER_INSTALL_PREFIX = c_mc_rtc.MC_CONTROLLER_INSTALL_PREFIX
DATA_PATH = c_mc_rtc.DATA_PATH
CONF_PATH = c_mc_rtc.CONF_PATH

cdef c_eigen.Vector3d python_log_v3d(get_fn) with gil:
  cdef eigen.Vector3d ret = get_fn()
  return ret.impl

cdef double python_log_double(get_fn) with gil:
  return <double>get_fn()

cdef vector[double] python_log_doublev(get_fn) with gil:
  return get_fn()

cdef c_eigen.Quaterniond python_log_quat(get_fn) with gil:
  cdef eigen.Quaterniond ret = get_fn()
  return ret.impl

cdef c_sva.PTransformd python_log_pt(get_fn) with gil:
  cdef sva.PTransformd ret = get_fn()
  return c_sva.PTransformd(deref(ret.impl))

cdef c_sva.ForceVecd python_log_fv(get_fn) with gil:
  cdef sva.ForceVecd ret = get_fn()
  return c_sva.ForceVecd(deref(ret.impl))

cdef string python_log_string(get_fn) with gil:
  ret = get_fn()
  if isinstance(ret, unicode):
    ret = ret.encode(u'ascii')
  return ret

cdef class Logger(object):
  CALLBACKS = []
  def __cinit__(self):
    self.impl = NULL
  def addLogEntry(self, name, get_fn):
    if isinstance(name, unicode):
      name = name.encode(u'ascii')
    Logger.CALLBACKS.append(get_fn)
    ret = get_fn()
    if isinstance(ret, eigen.Vector3d):
      self.impl.addLogEntry[c_mc_rtc.function[c_eigen.Vector3d]](name, <c_mc_rtc.function[c_eigen.Vector3d]>(c_mc_rtc.make_v3d_log_callback(python_log_v3d, get_fn)))
    elif isinstance(ret, numbers.Number):
      self.impl.addLogEntry[c_mc_rtc.function[double]](name, c_mc_rtc.make_double_log_callback(python_log_double, get_fn))
    elif isinstance(ret, Iterable) and len(ret) and isinstance(ret[0], numbers.Number):
      self.impl.addLogEntry[c_mc_rtc.function[vector[double]]](name, c_mc_rtc.make_doublev_log_callback(python_log_doublev, get_fn))
    elif isinstance(ret, eigen.Quaterniond):
      self.impl.addLogEntry[c_mc_rtc.function[c_eigen.Quaterniond]](name, c_mc_rtc.make_quat_log_callback(python_log_quat, get_fn))
    elif isinstance(ret, sva.PTransformd):
      self.impl.addLogEntry[c_mc_rtc.function[c_sva.PTransformd]](name, c_mc_rtc.make_pt_log_callback(python_log_pt, get_fn))
    elif isinstance(ret, sva.ForceVecd):
      self.impl.addLogEntry[c_mc_rtc.function[c_sva.ForceVecd]](name, c_mc_rtc.make_fv_log_callback(python_log_fv, get_fn))
    elif isinstance(ret, str):
      self.impl.addLogEntry[c_mc_rtc.function[string]](name, c_mc_rtc.make_string_log_callback(python_log_string, get_fn))
    else:
      raise TypeError("Cannot convert a callback returning " + str(type(ret)))
  def removeLogEntry(self, name):
    if isinstance(name, unicode):
      name = name.encode(u'ascii')
    self.impl.removeLogEntry(name)

cdef Logger LoggerFromRef(c_mc_rtc.Logger & logger):
  cdef Logger ret = Logger()
  ret.impl = &logger
  return ret

cdef class Configuration(object):
  def __dealloc__(self):
    if self.own_impl__:
      del self.impl
  def __cinit__(self, *args, skip_alloc = False):
    if not skip_alloc:
      self.own_impl__ = True
      if(len(args) == 0):
        self.impl = new c_mc_rtc.Configuration()
      else:
        assert(len(args) == 1)
        path = args[0]
        if isinstance(path, unicode):
          path = path.encode(u'ascii')
        self.impl = new c_mc_rtc.Configuration(<string>(path))
    else:
      self.own_impl__ = False
      self.impl = NULL
  @staticmethod
  def fromData(data):
    if isinstance(data, unicode):
      data = data.encode(u'ascii')
    return ConfigurationFromValue(c_mc_rtc.ConfigurationFromData(data))
  # Convert Python object to Configuration
  @staticmethod
  def from_(value):
    t = type(value)
    cdef c_mc_rtc.Configuration ret
    if t is bool:
      ret = c_mc_rtc.get_as_config[cppbool](value)
    elif isinstance(t(), numbers.Integral):
      ret = c_mc_rtc.get_as_config[int](value)
    elif isinstance(t(), numbers.Number):
      ret = c_mc_rtc.get_as_config[double](value)
    elif t is str or t is unicode:
      value = value.encode(u'ascii')
      ret = c_mc_rtc.get_as_config[string](value)
    elif t is eigen.Vector2d:
      ret = c_mc_rtc.get_as_config[c_eigen.Vector2d]((<eigen.Vector2d>(value)).impl)
    elif t is eigen.Vector3d:
      ret = c_mc_rtc.get_as_config[c_eigen.Vector3d]((<eigen.Vector3d>(value)).impl)
    elif t is eigen.Vector6d:
      ret = c_mc_rtc.get_as_config[c_eigen.Vector6d]((<eigen.Vector6d>(value)).impl)
    elif t is eigen.VectorXd:
      ret = c_mc_rtc.get_as_config[c_eigen.VectorXd]((<eigen.VectorXd>(value)).impl)
    elif t is eigen.Quaterniond:
      ret = c_mc_rtc.get_as_config[c_eigen.Quaterniond]((<eigen.Quaterniond>(value)).impl)
    elif t is eigen.Matrix3d:
      ret = c_mc_rtc.get_as_config[c_eigen.Matrix3d]((<eigen.Matrix3d>(value)).impl)
    elif t is eigen.Matrix6d:
      ret = c_mc_rtc.get_as_config[c_eigen.Matrix6d]((<eigen.Matrix6d>(value)).impl)
    elif t is eigen.MatrixXd:
      ret = c_mc_rtc.get_as_config[c_eigen.MatrixXd]((<eigen.MatrixXd>(value)).impl)
    elif t is sva.PTransformd:
      ret = c_mc_rtc.get_as_config[c_sva.PTransformd](deref((<sva.PTransformd>(value)).impl))
    elif t is list:
      ret = c_mc_rtc.Configuration()
      ret = ret.array("l", len(value))
      for v in value:
        ret.push(deref((<Configuration>Configuration.from_(v)).impl))
    else:
        raise TypeError("{} cannot be converted to Configuration".format(t))
    return ConfigurationFromValue(ret)
  # Retrieve this object as an actual type
  def to(self, t, default = None):
    if default is None and not isinstance(t, type):
      return self.to(type(t), t)
    assert(default is None or isinstance(default, t))
    if t is Configuration:
      return self
    if t is bool:
      if default is not None:
        return c_mc_rtc.get_config_as[cppbool](deref(self.impl), <cppbool>default)
      else:
        return c_mc_rtc.get_config_as[cppbool](deref(self.impl))
    if isinstance(t(), numbers.Integral):
      if default is not None:
        return c_mc_rtc.get_config_as[int](deref(self.impl), <int>default)
      else:
        return c_mc_rtc.get_config_as[int](deref(self.impl))
    if isinstance(t(), numbers.Number):
      if default is not None:
        return c_mc_rtc.get_config_as[double](deref(self.impl), <double>default)
      else:
        return c_mc_rtc.get_config_as[double](deref(self.impl))
    if t is str or t is unicode:
      if default is not None:
        default = default.encode(u'ascii')
        return c_mc_rtc.get_config_as[string](deref(self.impl), <string>default).decode(u'ascii')
      else:
        return c_mc_rtc.get_config_as[string](deref(self.impl)).decode(u'ascii')
    if t is eigen.Vector2d:
      if default is not None:
        return eigen.Vector2dFromC(c_mc_rtc.get_config_as[c_eigen.Vector2d](deref(self.impl), (<eigen.Vector2d>(default)).impl))
      else:
        return eigen.Vector2dFromC(c_mc_rtc.get_config_as[c_eigen.Vector2d](deref(self.impl)))
    if t is eigen.Vector3d:
      if default is not None:
        return eigen.Vector3dFromC(c_mc_rtc.get_config_as[c_eigen.Vector3d](deref(self.impl), (<eigen.Vector3d>(default)).impl))
      else:
        return eigen.Vector3dFromC(c_mc_rtc.get_config_as[c_eigen.Vector3d](deref(self.impl)))
    if t is eigen.Vector6d:
      if default is not None:
        return eigen.Vector6dFromC(c_mc_rtc.get_config_as[c_eigen.Vector6d](deref(self.impl), (<eigen.Vector6d>(default)).impl))
      else:
        return eigen.Vector6dFromC(c_mc_rtc.get_config_as[c_eigen.Vector6d](deref(self.impl)))
    if t is eigen.VectorXd:
      if default is not None:
        return eigen.VectorXdFromC(c_mc_rtc.get_config_as[c_eigen.VectorXd](deref(self.impl), (<eigen.VectorXd>(default)).impl))
      else:
        return eigen.VectorXdFromC(c_mc_rtc.get_config_as[c_eigen.VectorXd](deref(self.impl)))
    if t is eigen.Quaterniond:
      if default is not None:
        return eigen.QuaterniondFromC(c_mc_rtc.get_config_as[c_eigen.Quaterniond](deref(self.impl), (<eigen.Quaterniond>(default)).impl))
      else:
        return eigen.QuaterniondFromC(c_mc_rtc.get_config_as[c_eigen.Quaterniond](deref(self.impl)))
    if t is eigen.Matrix3d:
      if default is not None:
        return eigen.Matrix3dFromC(c_mc_rtc.get_config_as[c_eigen.Matrix3d](deref(self.impl), (<eigen.Matrix3d>(default)).impl))
      else:
        return eigen.Matrix3dFromC(c_mc_rtc.get_config_as[c_eigen.Matrix3d](deref(self.impl)))
    if t is eigen.Matrix6d:
      if default is not None:
        return eigen.Matrix6dFromC(c_mc_rtc.get_config_as[c_eigen.Matrix6d](deref(self.impl), (<eigen.Matrix6d>(default)).impl))
      else:
        return eigen.Matrix6dFromC(c_mc_rtc.get_config_as[c_eigen.Matrix6d](deref(self.impl)))
    if t is eigen.MatrixXd:
      if default is not None:
        return eigen.MatrixXdFromC(c_mc_rtc.get_config_as[c_eigen.MatrixXd](deref(self.impl), (<eigen.MatrixXd>(default)).impl))
      else:
        return eigen.MatrixXdFromC(c_mc_rtc.get_config_as[c_eigen.MatrixXd](deref(self.impl)))
    if t is sva.PTransformd:
      if default is not None:
        return sva.PTransformdFromC(c_mc_rtc.get_config_as[c_sva.PTransformd](deref(self.impl), deref((<sva.PTransformd>(default)).impl)))
      else:
        return sva.PTransformdFromC(c_mc_rtc.get_config_as[c_sva.PTransformd](deref(self.impl)))
    if t is list:
      return [c.to(default[0]) for c in self]
    raise TypeError("Conversion to {} not supported".format(t))
  def load(self, other):
    if isinstance(other, Configuration):
      self.impl.load(deref((<Configuration>(other)).impl))
    else:
      if isinstance(other, unicode):
        other = other.encode(u'ascii')
      self.impl.load(<string>(other))
  def loadData(self, data):
    if isinstance(data, unicode):
      data = data.encode(u'ascii')
    self.impl.loadData(data)
  def save(self, path, pretty = True):
    if isinstance(path, unicode):
      path = path.encode(u'ascii')
    self.impl.save(path, pretty)
  def dump(self, pretty = False):
    return self.impl.dump(pretty)
  def has(self, key):
    if isinstance(key, unicode):
      key = key.encode(u'ascii')
    return self.impl.has(key)
  def empty(self):
    return self.impl.empty()
  def keys(self):
    return self.impl.keys()
  def size(self):
    return self.impl.size()
  def add(self, key, value = None):
    if isinstance(key, unicode):
      key = key.encode(u'ascii')
    if value is None:
      return ConfigurationFromValue(self.impl.add(key))
    else:
      self.impl.add(key, deref((<Configuration>(Configuration.from_(value))).impl))
  def array(self, key, size = 0):
    if isinstance(key, unicode):
      key = key.encode(u'ascii')
    return ConfigurationFromValue(self.impl.array(key, size))
  def push(self, value = None):
    self.impl.push(deref((<Configuration>(Configuration.from_(value))).impl))
  def remove(self, k):
    if isinstance(k, unicode):
      k = k.encode(u'ascii')
    return self.impl.remove(k)
  # Special methods
  def __call__(self, key, t = None):
    if isinstance(key, unicode):
      key = key.encode(u'ascii')
    if t is None:
      return ConfigurationFromValue(deref(self.impl)(key))
    default = None
    if not isinstance(t, type):
      default = t
      t = type(default)
    if default is None:
      return ConfigurationFromValue(deref(self.impl)(key)).to(t, default)
    try:
      return ConfigurationFromValue(deref(self.impl)(key)).to(t, default)
    except:
      return default
  def __getitem__(self, idx):
    if idx < self.size():
      return ConfigurationFromValue(deref(self.impl)[idx])
    else:
      raise IndexError("Out of bounds")

cdef Configuration ConfigurationFromValue(c_mc_rtc.Configuration conf):
  cdef Configuration ret = Configuration(skip_alloc = True)
  ret.own_impl__ = True
  ret.impl = new c_mc_rtc.Configuration(conf)
  return ret

cdef Configuration ConfigurationFromRef(c_mc_rtc.Configuration & conf):
  cdef Configuration ret = Configuration(skip_alloc = True)
  ret.impl = &conf
  return ret

# The datastore holds arbitrary C++ objects and can only report their type name,
# so the bindings keep a table of the types they know how to convert and
# dispatch on it. Only these types can be read from or written to the datastore
# from Python; anything else raises a TypeError.
cdef dict __DATASTORE_TAGS = {}

cdef dict datastore_tags():
  global __DATASTORE_TAGS
  if not __DATASTORE_TAGS:
    __DATASTORE_TAGS = {
      c_mc_rtc.type_name[cppbool]().decode(u'ascii'): u'bool',
      c_mc_rtc.type_name[int]().decode(u'ascii'): u'int',
      c_mc_rtc.type_name[c_mc_rtc.cppuint]().decode(u'ascii'): u'unsigned int',
      c_mc_rtc.type_name[size_t]().decode(u'ascii'): u'size_t',
      c_mc_rtc.type_name[double]().decode(u'ascii'): u'double',
      c_mc_rtc.type_name[string]().decode(u'ascii'): u'string',
      c_mc_rtc.type_name[vector[double]]().decode(u'ascii'): u'vector<double>',
      c_mc_rtc.type_name[vector[string]]().decode(u'ascii'): u'vector<string>',
      c_mc_rtc.type_name[c_eigen.Vector2d]().decode(u'ascii'): u'Vector2d',
      c_mc_rtc.type_name[c_eigen.Vector3d]().decode(u'ascii'): u'Vector3d',
      c_mc_rtc.type_name[c_eigen.Vector6d]().decode(u'ascii'): u'Vector6d',
      c_mc_rtc.type_name[c_eigen.VectorXd]().decode(u'ascii'): u'VectorXd',
      c_mc_rtc.type_name[c_eigen.Matrix3d]().decode(u'ascii'): u'Matrix3d',
      c_mc_rtc.type_name[c_eigen.Matrix6d]().decode(u'ascii'): u'Matrix6d',
      c_mc_rtc.type_name[c_eigen.MatrixXd]().decode(u'ascii'): u'MatrixXd',
      c_mc_rtc.type_name[c_eigen.Quaterniond]().decode(u'ascii'): u'Quaterniond',
      c_mc_rtc.type_name[c_sva.PTransformd]().decode(u'ascii'): u'PTransformd',
      c_mc_rtc.type_name[c_sva.MotionVecd]().decode(u'ascii'): u'MotionVecd',
      c_mc_rtc.type_name[c_sva.ForceVecd]().decode(u'ascii'): u'ForceVecd',
    }
  return __DATASTORE_TAGS

# Types the datastore bindings can convert, as returned by DataStore.tag() and
# accepted by DataStore.make()
DATASTORE_TYPES = [u'bool', u'int', u'unsigned int', u'size_t', u'double',
                   u'string', u'vector<double>', u'vector<string>',
                   u'Vector2d', u'Vector3d', u'Vector6d', u'VectorXd',
                   u'Matrix3d', u'Matrix6d', u'MatrixXd', u'Quaterniond',
                   u'PTransformd', u'MotionVecd', u'ForceVecd']

# Those all hold a Python number so they are interchangeable on write
DATASTORE_NUMERIC_TYPES = [u'bool', u'int', u'unsigned int', u'size_t', u'double']

cdef string datastore_key(name) except *:
  if isinstance(name, unicode):
    name = name.encode(u'ascii')
  return <string>(name)

# Type used to create a datastore object out of a Python value. Python does not
# distinguish the C++ integer types so an int always creates an int and a float
# always creates a double, use the type argument of make to pick another one
cdef object datastore_value_type(value):
  if isinstance(value, bool):
    return u'bool'
  if isinstance(value, eigen.Vector2d):
    return u'Vector2d'
  if isinstance(value, eigen.Vector3d):
    return u'Vector3d'
  if isinstance(value, eigen.Vector6d):
    return u'Vector6d'
  if isinstance(value, eigen.VectorXd):
    return u'VectorXd'
  if isinstance(value, eigen.Matrix3d):
    return u'Matrix3d'
  if isinstance(value, eigen.Matrix6d):
    return u'Matrix6d'
  if isinstance(value, eigen.MatrixXd):
    return u'MatrixXd'
  if isinstance(value, eigen.Quaterniond):
    return u'Quaterniond'
  if isinstance(value, sva.PTransformd):
    return u'PTransformd'
  if isinstance(value, sva.MotionVecd):
    return u'MotionVecd'
  if isinstance(value, sva.ForceVecd):
    return u'ForceVecd'
  if isinstance(value, numbers.Integral):
    return u'int'
  if isinstance(value, numbers.Number):
    return u'double'
  if isinstance(value, (str, unicode, bytes)):
    return u'string'
  if isinstance(value, Iterable):
    items = list(value)
    if all([isinstance(v, numbers.Number) and not isinstance(v, bool) for v in items]):
      return u'vector<double>'
    if all([isinstance(v, (str, unicode, bytes)) for v in items]):
      return u'vector<string>'
    raise TypeError("Only sequences of numbers or of strings can be stored in the datastore")
  raise TypeError("{} cannot be stored in the datastore".format(type(value).__name__))

cdef object datastore_checked(t, value, expected):
  if not isinstance(value, expected):
    raise TypeError("Datastore object of type {} cannot be set from a {}".format(t, type(value).__name__))
  return value

cdef vector[double] datastore_as_vecd(t, value) except *:
  cdef vector[double] out
  datastore_checked(t, value, Iterable)
  for v in value:
    out.push_back(<double>(datastore_checked(t, v, numbers.Number)))
  return out

cdef vector[string] datastore_as_vecs(t, value) except *:
  cdef vector[string] out
  datastore_checked(t, value, Iterable)
  for v in value:
    out.push_back(datastore_key(datastore_checked(t, v, (str, unicode, bytes))))
  return out

cdef class DataStore(object):
  """Access to an mc_rtc::DataStore

  Values are converted to and from Python so what is read is a copy: mutating
  the object returned by get() does not change the datastore, write it back with
  assign() (or the [] operator) instead.
  """
  def __dealloc__(self):
    if self.own_impl__:
      del self.impl
  def __cinit__(self, name = None, skip_alloc = False):
    if skip_alloc:
      self.own_impl__ = False
      self.impl = NULL
    else:
      self.own_impl__ = True
      self.impl = new c_mc_rtc.DataStore()
      if name is not None:
        self.impl.name(datastore_key(name))
  def name(self, name = None):
    if name is None:
      return self.impl.name().decode(u'ascii')
    self.impl.name(datastore_key(name))
  def has(self, name):
    return self.impl.has(datastore_key(name))
  def keys(self):
    # Through a local, iterating self.impl.keys() directly makes Cython take it
    # for a Python dict and iterate the DataStore pointer as a PyObject
    cdef vector[string] keys = self.impl.keys()
    return [k.decode(u'ascii') for k in keys]
  def type(self, name):
    """C++ type name of a stored object, as given by mc_rtc::type_name"""
    cdef string key = datastore_key(name)
    if not self.impl.has(key):
      raise KeyError(name)
    return self.impl.type(key).decode(u'ascii')
  def tag(self, name):
    """Type of a stored object as one of DATASTORE_TYPES

    Returns None when the object's type is not one the bindings can convert
    """
    return datastore_tags().get(self.type(name), None)
  def get(self, name, default = None):
    """Value of a stored object

    Raises KeyError when there is no such object and no default was given, and
    TypeError when the stored type is not supported by the bindings
    """
    cdef string key = datastore_key(name)
    if not self.impl.has(key):
      if default is None:
        raise KeyError(name)
      return default
    return self._get(key, self._tag(key))
  def make(self, name, value, t = None):
    """Create an object on the datastore

    @param t Type to create the object as, one of DATASTORE_TYPES, defaults to
    the type deduced from value

    Raises RuntimeError when an object of that name already exists
    """
    if t is None:
      t = datastore_value_type(value)
    elif t not in DATASTORE_TYPES:
      raise TypeError("{} is not a datastore type supported by the bindings".format(t))
    self._set(datastore_key(name), t, value, True)
  def assign(self, name, value):
    """Overwrite an existing object on the datastore

    The value is converted to the type the object was created with, so an
    existing size_t can be written from a Python int

    Raises KeyError when there is no such object
    """
    cdef string key = datastore_key(name)
    if not self.impl.has(key):
      raise KeyError(name)
    self._set(key, self._tag(key), value, False)
  def remove(self, name):
    cdef string key = datastore_key(name)
    if not self.impl.has(key):
      raise KeyError(name)
    self.impl.remove(key)
  def clear(self):
    self.impl.clear()
  def call(self, name, *args):
    """Invoke a supported zero-argument getter or one-argument setter."""
    cdef string key = datastore_key(name)
    if not self.impl.has(key):
      raise KeyError(name)
    signature = c_mc_rtc.datastore_callback_signature(deref(self.impl), key).decode(u'ascii')
    if not signature:
      raise TypeError('Datastore callback "{}" has unsupported signature {}'.format(name, self.type(name)))
    if signature == u'call:void':
      if args:
        raise TypeError('Datastore callback "{}" expects no arguments'.format(name))
      c_mc_rtc.datastore_call_void(deref(self.impl), key)
      return None
    operation, t, qualifier = signature.split(u':')
    if operation == u'get':
      if args:
        raise TypeError('Datastore getter "{}" expects no arguments'.format(name))
      return self._call_get(key, t, qualifier == u'const_ref')
    if len(args) != 1:
      raise TypeError('Datastore setter "{}" expects one argument'.format(name))
    self._call_set(key, t, args[0], qualifier == u'const_ref')
    return None
  # Special methods
  def __getitem__(self, name):
    cdef string key = datastore_key(name)
    if not self.impl.has(key):
      raise KeyError(name)
    return self._get(key, self._tag(key))
  def __setitem__(self, name, value):
    """Create the object when it does not exist yet, overwrite it otherwise"""
    cdef string key = datastore_key(name)
    if self.impl.has(key):
      self._set(key, self._tag(key), value, False)
    else:
      self._set(key, datastore_value_type(value), value, True)
  def __delitem__(self, name):
    self.remove(name)
  def __contains__(self, name):
    return self.impl.has(datastore_key(name))
  def __len__(self):
    cdef vector[string] keys = self.impl.keys()
    return keys.size()
  def __iter__(self):
    return iter(self.keys())
  def __repr__(self):
    return "{}({})".format(self.name(), ", ".join(sorted(self.keys())))
  # Type dispatch, the datastore only knows the type of its objects at runtime
  cdef object _tag(self, string key):
    t = self.impl.type(key).decode(u'ascii')
    tag = datastore_tags().get(t, None)
    if tag is None:
      raise TypeError('Datastore object "{}" holds a {} which the Python bindings cannot handle'.format(key.decode(u'ascii'), t))
    return tag
  cdef object _get(self, string key, t):
    cdef vector[string] vs
    if t == u'bool':
      return self.impl.get[cppbool](key)
    elif t == u'int':
      return self.impl.get[int](key)
    elif t == u'unsigned int':
      return self.impl.get[c_mc_rtc.cppuint](key)
    elif t == u'size_t':
      return self.impl.get[size_t](key)
    elif t == u'double':
      return self.impl.get[double](key)
    elif t == u'string':
      return self.impl.get[string](key).decode(u'ascii')
    elif t == u'vector<double>':
      return self.impl.get[vector[double]](key)
    elif t == u'vector<string>':
      vs = self.impl.get[vector[string]](key)
      return [v.decode(u'ascii') for v in vs]
    elif t == u'Vector2d':
      return eigen.Vector2dFromC(self.impl.get[c_eigen.Vector2d](key))
    elif t == u'Vector3d':
      return eigen.Vector3dFromC(self.impl.get[c_eigen.Vector3d](key))
    elif t == u'Vector6d':
      return eigen.Vector6dFromC(self.impl.get[c_eigen.Vector6d](key))
    elif t == u'VectorXd':
      return eigen.VectorXdFromC(self.impl.get[c_eigen.VectorXd](key))
    elif t == u'Matrix3d':
      return eigen.Matrix3dFromC(self.impl.get[c_eigen.Matrix3d](key))
    elif t == u'Matrix6d':
      return eigen.Matrix6dFromC(self.impl.get[c_eigen.Matrix6d](key))
    elif t == u'MatrixXd':
      return eigen.MatrixXdFromC(self.impl.get[c_eigen.MatrixXd](key))
    elif t == u'Quaterniond':
      return eigen.QuaterniondFromC(self.impl.get[c_eigen.Quaterniond](key))
    elif t == u'PTransformd':
      return sva.PTransformdFromC(self.impl.get[c_sva.PTransformd](key))
    elif t == u'MotionVecd':
      return sva.MotionVecdFromC(self.impl.get[c_sva.MotionVecd](key))
    elif t == u'ForceVecd':
      return sva.ForceVecdFromC(self.impl.get[c_sva.ForceVecd](key))
    raise TypeError("Cannot read a datastore object of type {}".format(t))
  cdef object _call_get(self, string key, t, cppbool const_ref):
    cdef vector[string] vs
    if t == u'bool':
      return c_mc_rtc.datastore_call_get[cppbool](deref(self.impl), key, const_ref)
    elif t == u'int':
      return c_mc_rtc.datastore_call_get[int](deref(self.impl), key, const_ref)
    elif t == u'unsigned int':
      return c_mc_rtc.datastore_call_get[c_mc_rtc.cppuint](deref(self.impl), key, const_ref)
    elif t == u'size_t':
      return c_mc_rtc.datastore_call_get[size_t](deref(self.impl), key, const_ref)
    elif t == u'double':
      return c_mc_rtc.datastore_call_get[double](deref(self.impl), key, const_ref)
    elif t == u'string':
      return c_mc_rtc.datastore_call_get[string](deref(self.impl), key, const_ref).decode(u'ascii')
    elif t == u'vector<double>':
      return c_mc_rtc.datastore_call_get[vector[double]](deref(self.impl), key, const_ref)
    elif t == u'vector<string>':
      vs = c_mc_rtc.datastore_call_get[vector[string]](deref(self.impl), key, const_ref)
      return [v.decode(u'ascii') for v in vs]
    elif t == u'Vector2d':
      return eigen.Vector2dFromC(c_mc_rtc.datastore_call_get[c_eigen.Vector2d](deref(self.impl), key, const_ref))
    elif t == u'Vector3d':
      return eigen.Vector3dFromC(c_mc_rtc.datastore_call_get[c_eigen.Vector3d](deref(self.impl), key, const_ref))
    elif t == u'Vector6d':
      return eigen.Vector6dFromC(c_mc_rtc.datastore_call_get[c_eigen.Vector6d](deref(self.impl), key, const_ref))
    elif t == u'VectorXd':
      return eigen.VectorXdFromC(c_mc_rtc.datastore_call_get[c_eigen.VectorXd](deref(self.impl), key, const_ref))
    elif t == u'Matrix3d':
      return eigen.Matrix3dFromC(c_mc_rtc.datastore_call_get[c_eigen.Matrix3d](deref(self.impl), key, const_ref))
    elif t == u'Matrix6d':
      return eigen.Matrix6dFromC(c_mc_rtc.datastore_call_get[c_eigen.Matrix6d](deref(self.impl), key, const_ref))
    elif t == u'MatrixXd':
      return eigen.MatrixXdFromC(c_mc_rtc.datastore_call_get[c_eigen.MatrixXd](deref(self.impl), key, const_ref))
    elif t == u'Quaterniond':
      return eigen.QuaterniondFromC(c_mc_rtc.datastore_call_get[c_eigen.Quaterniond](deref(self.impl), key, const_ref))
    elif t == u'PTransformd':
      return sva.PTransformdFromC(c_mc_rtc.datastore_call_get[c_sva.PTransformd](deref(self.impl), key, const_ref))
    elif t == u'MotionVecd':
      return sva.MotionVecdFromC(c_mc_rtc.datastore_call_get[c_sva.MotionVecd](deref(self.impl), key, const_ref))
    elif t == u'ForceVecd':
      return sva.ForceVecdFromC(c_mc_rtc.datastore_call_get[c_sva.ForceVecd](deref(self.impl), key, const_ref))
    raise TypeError("Cannot return a datastore callback value of type {}".format(t))
  cdef void _call_set(self, string key, t, value, cppbool const_ref) except *:
    cdef vector[double] vd
    cdef vector[string] vs
    if t in DATASTORE_NUMERIC_TYPES:
      datastore_checked(t, value, numbers.Number)
    if t == u'bool':
      c_mc_rtc.datastore_call_set[cppbool](deref(self.impl), key, <cppbool>(value), const_ref)
    elif t == u'int':
      c_mc_rtc.datastore_call_set[int](deref(self.impl), key, <int>(value), const_ref)
    elif t == u'unsigned int':
      c_mc_rtc.datastore_call_set[c_mc_rtc.cppuint](deref(self.impl), key, <c_mc_rtc.cppuint>(value), const_ref)
    elif t == u'size_t':
      c_mc_rtc.datastore_call_set[size_t](deref(self.impl), key, <size_t>(value), const_ref)
    elif t == u'double':
      c_mc_rtc.datastore_call_set[double](deref(self.impl), key, <double>(value), const_ref)
    elif t == u'string':
      c_mc_rtc.datastore_call_set[string](deref(self.impl), key, datastore_key(datastore_checked(t, value, (str, unicode, bytes))), const_ref)
    elif t == u'vector<double>':
      vd = datastore_as_vecd(t, value)
      c_mc_rtc.datastore_call_set[vector[double]](deref(self.impl), key, vd, const_ref)
    elif t == u'vector<string>':
      vs = datastore_as_vecs(t, value)
      c_mc_rtc.datastore_call_set[vector[string]](deref(self.impl), key, vs, const_ref)
    elif t == u'Vector2d':
      c_mc_rtc.datastore_call_set[c_eigen.Vector2d](deref(self.impl), key, (<eigen.Vector2d>(datastore_checked(t, value, eigen.Vector2d))).impl, const_ref)
    elif t == u'Vector3d':
      c_mc_rtc.datastore_call_set[c_eigen.Vector3d](deref(self.impl), key, (<eigen.Vector3d>(datastore_checked(t, value, eigen.Vector3d))).impl, const_ref)
    elif t == u'Vector6d':
      c_mc_rtc.datastore_call_set[c_eigen.Vector6d](deref(self.impl), key, (<eigen.Vector6d>(datastore_checked(t, value, eigen.Vector6d))).impl, const_ref)
    elif t == u'VectorXd':
      c_mc_rtc.datastore_call_set[c_eigen.VectorXd](deref(self.impl), key, (<eigen.VectorXd>(datastore_checked(t, value, eigen.VectorXd))).impl, const_ref)
    elif t == u'Matrix3d':
      c_mc_rtc.datastore_call_set[c_eigen.Matrix3d](deref(self.impl), key, (<eigen.Matrix3d>(datastore_checked(t, value, eigen.Matrix3d))).impl, const_ref)
    elif t == u'Matrix6d':
      c_mc_rtc.datastore_call_set[c_eigen.Matrix6d](deref(self.impl), key, (<eigen.Matrix6d>(datastore_checked(t, value, eigen.Matrix6d))).impl, const_ref)
    elif t == u'MatrixXd':
      c_mc_rtc.datastore_call_set[c_eigen.MatrixXd](deref(self.impl), key, (<eigen.MatrixXd>(datastore_checked(t, value, eigen.MatrixXd))).impl, const_ref)
    elif t == u'Quaterniond':
      c_mc_rtc.datastore_call_set[c_eigen.Quaterniond](deref(self.impl), key, (<eigen.Quaterniond>(datastore_checked(t, value, eigen.Quaterniond))).impl, const_ref)
    elif t == u'PTransformd':
      c_mc_rtc.datastore_call_set[c_sva.PTransformd](deref(self.impl), key, deref((<sva.PTransformd>(datastore_checked(t, value, sva.PTransformd))).impl), const_ref)
    elif t == u'MotionVecd':
      c_mc_rtc.datastore_call_set[c_sva.MotionVecd](deref(self.impl), key, deref((<sva.MotionVecd>(datastore_checked(t, value, sva.MotionVecd))).impl), const_ref)
    elif t == u'ForceVecd':
      c_mc_rtc.datastore_call_set[c_sva.ForceVecd](deref(self.impl), key, deref((<sva.ForceVecd>(datastore_checked(t, value, sva.ForceVecd))).impl), const_ref)
    else:
      raise TypeError("Cannot call a datastore setter of type {}".format(t))
  cdef void _set(self, string key, t, value, cppbool create) except *:
    cdef vector[double] vd
    cdef vector[string] vs
    if t in DATASTORE_NUMERIC_TYPES:
      datastore_checked(t, value, numbers.Number)
    if t == u'bool':
      c_mc_rtc.datastore_set[cppbool](deref(self.impl), key, <cppbool>(value), create)
    elif t == u'int':
      c_mc_rtc.datastore_set[int](deref(self.impl), key, <int>(value), create)
    elif t == u'unsigned int':
      c_mc_rtc.datastore_set[c_mc_rtc.cppuint](deref(self.impl), key, <c_mc_rtc.cppuint>(value), create)
    elif t == u'size_t':
      c_mc_rtc.datastore_set[size_t](deref(self.impl), key, <size_t>(value), create)
    elif t == u'double':
      c_mc_rtc.datastore_set[double](deref(self.impl), key, <double>(value), create)
    elif t == u'string':
      c_mc_rtc.datastore_set[string](deref(self.impl), key, datastore_key(datastore_checked(t, value, (str, unicode, bytes))), create)
    elif t == u'vector<double>':
      vd = datastore_as_vecd(t, value)
      c_mc_rtc.datastore_set[vector[double]](deref(self.impl), key, vd, create)
    elif t == u'vector<string>':
      vs = datastore_as_vecs(t, value)
      c_mc_rtc.datastore_set[vector[string]](deref(self.impl), key, vs, create)
    elif t == u'Vector2d':
      c_mc_rtc.datastore_set[c_eigen.Vector2d](deref(self.impl), key, (<eigen.Vector2d>(datastore_checked(t, value, eigen.Vector2d))).impl, create)
    elif t == u'Vector3d':
      c_mc_rtc.datastore_set[c_eigen.Vector3d](deref(self.impl), key, (<eigen.Vector3d>(datastore_checked(t, value, eigen.Vector3d))).impl, create)
    elif t == u'Vector6d':
      c_mc_rtc.datastore_set[c_eigen.Vector6d](deref(self.impl), key, (<eigen.Vector6d>(datastore_checked(t, value, eigen.Vector6d))).impl, create)
    elif t == u'VectorXd':
      c_mc_rtc.datastore_set[c_eigen.VectorXd](deref(self.impl), key, (<eigen.VectorXd>(datastore_checked(t, value, eigen.VectorXd))).impl, create)
    elif t == u'Matrix3d':
      c_mc_rtc.datastore_set[c_eigen.Matrix3d](deref(self.impl), key, (<eigen.Matrix3d>(datastore_checked(t, value, eigen.Matrix3d))).impl, create)
    elif t == u'Matrix6d':
      c_mc_rtc.datastore_set[c_eigen.Matrix6d](deref(self.impl), key, (<eigen.Matrix6d>(datastore_checked(t, value, eigen.Matrix6d))).impl, create)
    elif t == u'MatrixXd':
      c_mc_rtc.datastore_set[c_eigen.MatrixXd](deref(self.impl), key, (<eigen.MatrixXd>(datastore_checked(t, value, eigen.MatrixXd))).impl, create)
    elif t == u'Quaterniond':
      c_mc_rtc.datastore_set[c_eigen.Quaterniond](deref(self.impl), key, (<eigen.Quaterniond>(datastore_checked(t, value, eigen.Quaterniond))).impl, create)
    elif t == u'PTransformd':
      c_mc_rtc.datastore_set[c_sva.PTransformd](deref(self.impl), key, deref((<sva.PTransformd>(datastore_checked(t, value, sva.PTransformd))).impl), create)
    elif t == u'MotionVecd':
      c_mc_rtc.datastore_set[c_sva.MotionVecd](deref(self.impl), key, deref((<sva.MotionVecd>(datastore_checked(t, value, sva.MotionVecd))).impl), create)
    elif t == u'ForceVecd':
      c_mc_rtc.datastore_set[c_sva.ForceVecd](deref(self.impl), key, deref((<sva.ForceVecd>(datastore_checked(t, value, sva.ForceVecd))).impl), create)
    else:
      raise TypeError("Cannot write a datastore object of type {}".format(t))

cdef DataStore DataStoreFromRef(c_mc_rtc.DataStore & store):
  cdef DataStore ret = DataStore(skip_alloc = True)
  ret.impl = &store
  return ret

class Loader(object):
  @staticmethod
  def debug_suffix(suffix):
    if isinstance(suffix, unicode):
      suffix = suffix.encode(u'ascii')
    c_mc_rtc.set_loader_debug_suffix(suffix)
