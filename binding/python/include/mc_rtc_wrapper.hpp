/*
 * Copyright 2015-2020 CNRS-UM LIRMM, CNRS-AIST JRL
 */

#pragma once

#include <mc_rbdyn/configuration_io.h>
#include <mc_rtc/Configuration.h>
#include <mc_rtc/DataStore.h>
#include <mc_rtc/loader.h>

#include <SpaceVecAlg/SpaceVecAlg>

#include <Eigen/Core>
#include <functional>

template<typename T>
using function = std::function<T()>;

template<typename retT, typename T, typename U>
std::function<retT()> make_log_callback(T fn, U arg)
{
  return [fn, arg] { return fn(arg); };
}

#define MAKE_LOG_HELPER(NAME, TYPE)       \
  template<typename T, typename U>        \
  std::function<TYPE()> NAME(T fn, U arg) \
  { return make_log_callback<TYPE>(fn, arg); }
MAKE_LOG_HELPER(make_v3d_log_callback, Eigen::Vector3d)
MAKE_LOG_HELPER(make_double_log_callback, double)
MAKE_LOG_HELPER(make_doublev_log_callback, std::vector<double>)
MAKE_LOG_HELPER(make_quat_log_callback, Eigen::Quaterniond)
MAKE_LOG_HELPER(make_pt_log_callback, sva::PTransformd)
MAKE_LOG_HELPER(make_fv_log_callback, sva::ForceVecd)
MAKE_LOG_HELPER(make_string_log_callback, std::string)

template<typename T>
T get_config_as(mc_rtc::Configuration & config)
{
  T ret = config;
  return ret;
}

template<typename T>
T get_config_as(mc_rtc::Configuration & config, const T & def)
{
  try
  {
    return get_config_as<T>(config);
  }
  catch(const mc_rtc::Configuration::Exception &)
  {
    return def;
  }
}

template<typename T>
mc_rtc::Configuration get_as_config(const T & v)
{
  mc_rtc::Configuration conf;
  conf.add("v", v);
  return conf("v");
}

inline mc_rtc::Configuration ConfigurationFromData(const std::string & data)
{ return mc_rtc::Configuration::fromData(data); }

inline void set_loader_debug_suffix(const std::string & suffix)
{ mc_rtc::Loader::debug_suffix = suffix; }

/** Create or overwrite a datastore object
 *
 * Cython has no way to select between two calls in a single expression, so the
 * make/assign choice is made here to avoid duplicating the (long) type dispatch
 * on the Python side.
 *
 * @param create When true the object must not exist yet, otherwise it must
 * already exist and hold a T
 */
template<typename T>
void datastore_set(mc_rtc::DataStore & store, const std::string & name, const T & value, bool create)
{
  if(create) { store.make<T>(name, value); }
  else { store.assign<T>(name, value); }
}

template<typename T>
std::string datastore_callback_signature(const std::string & actual, const std::string & tag)
{
  if(actual == mc_rtc::type_name<std::function<T()>>()) { return "get:" + tag + ":value"; }
  if(actual == mc_rtc::type_name<std::function<const T &()>>()) { return "get:" + tag + ":const_ref"; }
  if(actual == mc_rtc::type_name<std::function<void(T)>>()) { return "set:" + tag + ":value"; }
  if(actual == mc_rtc::type_name<std::function<void(const T &)>>()) { return "set:" + tag + ":const_ref"; }
  return {};
}

/** Return the Python-supported getter/setter signature for a datastore callback. */
inline std::string datastore_callback_signature(mc_rtc::DataStore & store, const std::string & name)
{
  using Matrix6d = Eigen::Matrix<double, 6, 6>;
  const auto & actual = store.type(name);
  if(actual == mc_rtc::type_name<std::function<void()>>()) { return "call:void"; }
  std::string out;
#define HANDLE_DATASTORE_CALLBACK(TYPE, TAG)                  \
  out = datastore_callback_signature<TYPE>(actual, TAG);     \
  if(!out.empty()) { return out; }
  HANDLE_DATASTORE_CALLBACK(bool, "bool")
  HANDLE_DATASTORE_CALLBACK(int, "int")
  HANDLE_DATASTORE_CALLBACK(unsigned int, "unsigned int")
  HANDLE_DATASTORE_CALLBACK(size_t, "size_t")
  HANDLE_DATASTORE_CALLBACK(double, "double")
  HANDLE_DATASTORE_CALLBACK(std::string, "string")
  HANDLE_DATASTORE_CALLBACK(std::vector<double>, "vector<double>")
  HANDLE_DATASTORE_CALLBACK(std::vector<std::string>, "vector<string>")
  HANDLE_DATASTORE_CALLBACK(Eigen::Vector2d, "Vector2d")
  HANDLE_DATASTORE_CALLBACK(Eigen::Vector3d, "Vector3d")
  HANDLE_DATASTORE_CALLBACK(Eigen::Vector6d, "Vector6d")
  HANDLE_DATASTORE_CALLBACK(Eigen::VectorXd, "VectorXd")
  HANDLE_DATASTORE_CALLBACK(Eigen::Matrix3d, "Matrix3d")
  HANDLE_DATASTORE_CALLBACK(Matrix6d, "Matrix6d")
  HANDLE_DATASTORE_CALLBACK(Eigen::MatrixXd, "MatrixXd")
  HANDLE_DATASTORE_CALLBACK(Eigen::Quaterniond, "Quaterniond")
  HANDLE_DATASTORE_CALLBACK(sva::PTransformd, "PTransformd")
  HANDLE_DATASTORE_CALLBACK(sva::MotionVecd, "MotionVecd")
  HANDLE_DATASTORE_CALLBACK(sva::ForceVecd, "ForceVecd")
#undef HANDLE_DATASTORE_CALLBACK
  return {};
}

inline void datastore_call_void(mc_rtc::DataStore & store, const std::string & name)
{
  store.call<void>(name);
}

template<typename T>
T datastore_call_get(mc_rtc::DataStore & store, const std::string & name, bool const_ref)
{
  if(const_ref) { return store.call<const T &>(name); }
  return store.call<T>(name);
}

template<typename T>
void datastore_call_set(mc_rtc::DataStore & store, const std::string & name, const T & value, bool const_ref)
{
  if(const_ref) { store.call<void, const T &>(name, value); }
  else { store.call<void, T>(name, value); }
}
