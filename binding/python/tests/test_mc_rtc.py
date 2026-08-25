#
# Copyright 2015-2019 CNRS-UM LIRMM, CNRS-AIST JRL
#

import mc_rtc

import eigen
import sva

import os
import pytest
import tempfile


def makeConfigFile(data):
    f = tempfile.NamedTemporaryFile(delete=False)
    f.write(data.encode("ascii"))
    f.close()
    return f.name


def sampleConfig(fromDisk):
    data = """{
  "int": 42,
  "sint": -42,
  "double": 42.5,
  "doubleOrInt": 42.0,
  "string": "sometext",
  "intV": [0, 1, 2, 3, 4, 5],
  "stringV": ["a", "b", "c", "foo", "bar"],
  "doubleA3": [1.1, 2.2, 3.3],
  "v3d": [1.0, 2.3, -100],
  "v6d": [1.0, -1.5, 2.0, -2.5, 3.0, -3.5],
  "vXd": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  "quat": [0.71, 0, 0.71, 0],
  "emptyArray": [],
  "boolTrue": true,
  "boolFalse": false,
  "bool1": 1,
  "bool0": 0,
  "doubleDoublePair": [42.5, -42.5],
  "doubleStringPair": [42.5, "sometext"],
  "doubleDoublePairV": [[0.0, 1.1],[2.2, 3.3], [4.4, 5.5]],
  "tuple" : [true, 42.42, "sometext", [1.2, 3.4, 5.6]],
  "dict":
  {
    "boolTrue": true,
    "bool0": 0,
    "int" : 42,
    "double": 42.5,
    "string": "sometext",
    "intV": [0, 1, 2, 3, 4, 5],
    "stringV": ["a", "b", "c", "foo", "bar"],
    "v3d": [1.0, 2.3, -100],
    "v6d": [1.0, -1.5, 2.0, -2.5, 3.0, -3.5],
    "quat": [0.71, 0, 0.71, 0],
    "doubleDoublePair": [42.5, -42.5],
    "doubleStringPair": [42.5, "sometext"]
  },
  "mapStr":
  {
    "str1": "sometext1",
    "str2": "sometext2",
    "str3": "sometext3",
    "str4": "sometext4"
  },
  "mapDouble":
  {
    "str1" : 1.1,
    "str2" : 2.2,
    "str3" : 3.3,
    "str4" : 4.4
  },
  "mapDoubleV":
  {
    "str1": [1.0, 2.3, -100],
    "str2": [1.0, -1.5, 2.0, -2.5, 3.0, -3.5],
    "str3": [0.71, 0, 0.71, 0]
  }
}"""
    if fromDisk:
        return makeConfigFile(data)
    else:
        return data


def sampleConfig2(fromDisk):
    data = """{
    "stringV": ["a2", "b2", "c2"],
    "int": 12
  }"""
    if fromDisk:
        return makeConfigFile(data)
    else:
        return data


def do_configuration_reading(config, fromDisk2):
    with pytest.raises(RuntimeError):
        config("NONE")

    assert config("int", int) == 42
    assert config("int", 0) == 42
    assert config("NONE", 100) == 100
    assert config("dict")("int", int) == 42

    assert config("double", float) == 42.5
    assert config("double", 0.0) == 42.5
    assert config("NONE", 42.42) == 42.42
    assert config("dict")("double", float) == 42.5

    assert config("string", str) == "sometext"
    try:
        assert config("string", unicode) == "sometext"
    except NameError:
        pass
    assert config("string", "") == "sometext"
    assert config("string", "") == "sometext"
    assert config("NONE", "another") == "another"
    assert config("dict")("string", "") == "sometext"

    ref = eigen.Vector3d(1.0, 2.3, -100)
    zero = eigen.Vector3d.Zero()
    assert config("v3d", eigen.Vector3d) == ref
    assert config("v3d", zero) == ref
    assert config("v6d", zero) == zero
    with pytest.raises(RuntimeError):
        config("v6d", eigen.Vector3d)
    assert config("dict")("v3d", eigen.Vector3d) == ref
    assert config("dict")("v3d", zero) == ref

    ref = eigen.Vector6d(1.0, -1.5, 2.0, -2.5, 3.0, -3.5)
    zero = eigen.Vector6d.Zero()
    assert config("v6d", eigen.Vector6d) == ref
    assert config("v6d", zero) == ref
    assert config("v3d", zero) == zero
    with pytest.raises(RuntimeError):
        config("v3d", eigen.Vector6d)
    assert config("dict")("v6d", eigen.Vector6d) == ref
    assert config("dict")("v6d", zero) == ref

    ref3 = eigen.VectorXd(1, 2.3, -100)
    ref6 = eigen.VectorXd(ref)
    ref = eigen.VectorXd(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    assert config("v6d", eigen.VectorXd) == ref6
    assert config("v3d", eigen.VectorXd) == ref3
    assert config("vXd", eigen.VectorXd) == ref
    with pytest.raises(RuntimeError):
        config("int", eigen.VectorXd)
    assert config("dict")("v6d", eigen.VectorXd) == ref6
    assert config("dict")("v3d", eigen.VectorXd) == ref3
    assert config("emptyArray", eigen.VectorXd.Zero(100)) == eigen.VectorXd.Zero(0)

    ref = eigen.Quaterniond(0.71, 0, 0.71, 0)
    ref.normalize()
    assert config("quat", eigen.Quaterniond).isApprox(ref)
    assert config("dict")("quat", eigen.Quaterniond).isApprox(ref)

    assert config("boolTrue", bool)
    assert config("boolTrue", False)
    assert not config("boolFalse", bool)
    assert not config("boolFalse", True)
    assert config("bool1", bool)
    assert not config("bool0", bool)
    assert config("dict")("boolTrue", bool)
    assert not config("dict")("bool0", bool)

    ref = [0, 1, 2, 3, 4, 5]
    assert [c.to(int) for c in config("intV")] == ref
    assert [c.to(int) for c in config("dict")("intV")] == ref
    assert [c.to(float) for c in config("intV")] == ref
    assert [c.to(float) for c in config("dict")("intV")] == ref
    assert config("intV", [int]) == ref
    assert config("intV", [0]) == ref

    ref = ["a", "b", "c", "foo", "bar"]
    assert [c.to(str) for c in config("stringV")] == ref
    assert [c.to(str) for c in config("dict")("stringV")] == ref

    ref = [1.1, 2.2, 3.3]
    assert [c.to(float) for c in config("doubleA3")] == ref

    ref = [42.5, -42.5]
    assert [c.to(float) for c in config("doubleDoublePair")] == ref

    ref = [42.5, "sometext"]
    c = config("doubleStringPair")
    assert [c[0].to(float), c[1].to(str)] == ref

    if fromDisk2:
        file = sampleConfig2(True)
        config.load(file)
        os.remove(file)
    else:
        config.loadData(sampleConfig2(False))

    assert config("int", int) == 12
    assert config("sint", int) == -42

    ref = ["a2", "b2", "c2"]
    assert [c.to(str) for c in config("stringV")] == ref


def test_configuration_reading_disk_disk():
    file = sampleConfig(True)
    config = mc_rtc.Configuration(file)
    os.remove(file)
    do_configuration_reading(config, True)


def test_configuration_reading_disk_data():
    file = sampleConfig(True)
    config = mc_rtc.Configuration(file)
    os.remove(file)
    do_configuration_reading(config, False)


def test_configuration_reading_data_disk():
    config = mc_rtc.Configuration.fromData(sampleConfig(False))
    do_configuration_reading(config, True)


def test_configuration_reading_data_data():
    config = mc_rtc.Configuration.fromData(sampleConfig(False))
    do_configuration_reading(config, False)


def test_configuration_writing():
    tmpF = tempfile.NamedTemporaryFile(delete=False).name
    config_ref = mc_rtc.Configuration()

    ref_bool = False
    config_ref.add("bool", ref_bool)
    ref_uint = 42
    config_ref.add("uint", ref_uint)
    ref_int = -42
    config_ref.add("int", ref_int)
    ref_double = 42.5
    config_ref.add("double", ref_double)
    ref_string = "sometext"
    config_ref.add("string", ref_string)
    ref_v3d = eigen.Vector3d(1.2, 3.4, 5.6)
    config_ref.add("v3d", ref_v3d)
    ref_v6d = eigen.Vector6d(0.1, 1.2, 2.3, 3.4, 4.5, 5.6)
    config_ref.add("v6d", ref_v6d)
    ref_vxd = eigen.VectorXd(0.1, 3.2, 4.2, 4.5, 5.4)
    config_ref.add("vxd", ref_vxd)
    ref_quat = eigen.Quaterniond(0.71, 0, 0.71, 0)
    ref_quat.normalize()
    config_ref.add("quat", ref_quat)
    ref_int_v = [0, 1, 2, 3, 4, 5]
    config_ref.add("int_v", ref_int_v)
    ref_double_v = [0.1, 1.0, 0.2, 2.0, 0.3]
    config_ref.add("double_v", ref_double_v)
    ref_double_v_v = [ref_double_v, ref_double_v, [0], [], [5.0, 4.0, 3.5]]
    config_ref.add("double_v_v", ref_double_v_v)
    ref_v3d_v = [eigen.Vector3d.Random() for i in range(10)]
    config_ref.add("v3d_v", ref_v3d_v)
    config_ref.add("dict")
    config_ref("dict").add("int", ref_int)
    config_ref.add("dict2").add("double_v", ref_double_v)

    config_ref.save(tmpF)

    config_test = mc_rtc.Configuration(tmpF)
    assert config_test("bool", bool) == ref_bool
    assert config_test("uint", int) == ref_uint
    assert config_test("int", int) == ref_int
    assert config_test("double", float) == ref_double
    assert config_test("string", str) == ref_string
    assert config_test("v3d", eigen.Vector3d) == ref_v3d
    assert config_test("v6d", eigen.Vector6d) == ref_v6d
    assert config_test("vxd", eigen.VectorXd) == ref_vxd
    assert config_test("quat", eigen.Quaterniond).isApprox(ref_quat)
    assert config_test("int_v", [int]) == ref_int_v
    assert config_test("double_v", [float]) == ref_double_v
    assert config_test("double_v_v", [[0.0]]) == ref_double_v_v
    assert all(
        [
            (v - ref_v).norm() < 1e-9
            for v, ref_v in zip(config_test("v3d_v", [eigen.Vector3d]), ref_v3d_v)
        ]
    )
    assert config_test("dict")("int", int) == ref_int
    assert config_test("dict2")("double_v", [float]) == ref_double_v

    config_test("dict2")("double_v").save(tmpF)
    assert mc_rtc.Configuration(tmpF).to([float]) == ref_double_v

    os.remove(tmpF)


def test_datastore_creation():
    ds = mc_rtc.DataStore()
    assert ds.name() == "DataStore"
    ds.name("TestStore")
    assert ds.name() == "TestStore"
    assert mc_rtc.DataStore("OtherStore").name() == "OtherStore"
    assert len(ds) == 0
    assert ds.keys() == []


def test_datastore_types():
    ds = mc_rtc.DataStore()
    ref = {
        "bool": True,
        "int": -42,
        "double": 42.5,
        "string": "sometext",
        "vector<double>": [0.1, 1.0, 0.2, 2.0, 0.3],
        "vector<string>": ["a", "b", "c"],
        "Vector2d": eigen.Vector2d(1.2, 3.4),
        "Vector3d": eigen.Vector3d(1.2, 3.4, 5.6),
        "Vector6d": eigen.Vector6d(0.1, 1.2, 2.3, 3.4, 4.5, 5.6),
        "VectorXd": eigen.VectorXd(0.1, 3.2, 4.2, 4.5, 5.4),
        "Matrix3d": eigen.Matrix3d.Random(),
        "Matrix6d": eigen.Matrix6d.Random(),
        "MatrixXd": eigen.MatrixXd.Random(4, 3),
        "Quaterniond": eigen.Quaterniond(0.71, 0, 0.71, 0).normalized(),
        "PTransformd": sva.PTransformd(eigen.Vector3d(1.0, 2.0, 3.0)),
        "MotionVecd": sva.MotionVecd(eigen.Vector6d(0.1, 1.2, 2.3, 3.4, 4.5, 5.6)),
        "ForceVecd": sva.ForceVecd(eigen.Vector6d(0.1, 1.2, 2.3, 3.4, 4.5, 5.6)),
    }
    for t, value in ref.items():
        ds.make(t, value)
    # Python has no distinct type for those so they are created explicitely
    ds.make("unsigned int", 42, "unsigned int")
    ds.make("size_t", 42, "size_t")

    assert len(ds) == len(ref) + 2
    assert sorted(ds.keys()) == sorted(list(ref.keys()) + ["unsigned int", "size_t"])
    for t in ds.keys():
        assert t in ds
        assert ds.tag(t) == t
    assert ds.get("unsigned int") == 42
    assert ds.get("size_t") == 42
    for t, value in ref.items():
        out = ds.get(t)
        assert type(out) is type(value)
        if t == "Quaterniond":
            assert out.isApprox(value)
        else:
            assert out == value


def test_datastore_access():
    ds = mc_rtc.DataStore()
    ds.make("double", 42.5)
    assert ds["double"] == 42.5
    # The stored type wins over the type of the value that is assigned
    ds.make("size_t", 42, "size_t")
    ds.assign("size_t", 12.0)
    assert ds.tag("size_t") == "size_t"
    assert ds["size_t"] == 12
    ds["size_t"] = 3
    assert ds.tag("size_t") == "size_t"
    assert ds["size_t"] == 3
    # [] creates the object when it does not exist yet
    ds["v3d"] = eigen.Vector3d(1.2, 3.4, 5.6)
    assert ds.tag("v3d") == "Vector3d"
    assert ds["v3d"] == eigen.Vector3d(1.2, 3.4, 5.6)
    assert sorted(iter(ds)) == sorted(ds.keys())
    assert ds.get("nokey", 42) == 42
    assert ds.get("double", 12.0) == 42.5
    del ds["v3d"]
    assert "v3d" not in ds
    ds.remove("double")
    assert "double" not in ds
    ds.clear()
    assert len(ds) == 0


def test_datastore_errors():
    ds = mc_rtc.DataStore()
    ds.make("double", 42.5)
    with pytest.raises(KeyError):
        ds.get("nokey")
    with pytest.raises(KeyError):
        ds["nokey"]
    with pytest.raises(KeyError):
        ds.assign("nokey", 42.0)
    with pytest.raises(KeyError):
        ds.remove("nokey")
    with pytest.raises(KeyError):
        ds.type("nokey")
    # Creating twice is an error, overwriting must be explicit
    with pytest.raises(RuntimeError):
        ds.make("double", 12.0)
    with pytest.raises(TypeError):
        ds.make("v3d", eigen.Vector3d.Zero(), "notatype")
    with pytest.raises(TypeError):
        ds.make("object", mc_rtc.Configuration())
    ds.make("v3d", eigen.Vector3d.Zero())
    with pytest.raises(TypeError):
        ds.assign("v3d", 42.0)
    with pytest.raises(TypeError):
        ds.assign("double", "notanumber")
    with pytest.raises(TypeError):
        ds.make("mixed", [1.0, "two"])
