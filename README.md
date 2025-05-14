alinkiot_csv
=====

import and export csv file for alinkiot
## export
-----
```erl
Data = [
  #{device_id => "000001", device_name => "A0000001"}, 
  #{device_id => "000002", device_name => "A0000002"},
  #{device_id => "000003", device_name => "A0000002"},
  #{device_id => "000004", device_name => "A0000002"},
  #{device_id => "000005", device_name => "A0000002"}
].
alinkiot_csv:export_csv("device", "csv/", Data).
```
device.csv
```csv
字段说明,,,
字段名称,字段标识,类型,说明
设备地址,device_id,string,Unique identifier for the device
设备名称,device_name,string,Name of the device
,,,
设备地址,设备名称,,
000001,A0000001,,
000002,A0000002,,
```

## template
-----
```erlang
alinkiot_csv:get_template("device", "csv/").
```
device_template.csv
```csv
设备地址,设备名称,,
```

## import
-----
device.csv
```csv
设备地址,设备名称,,
000001,A0000001,,
000002,A0000002,,
000003,A0000003,,
000004,A0000004,,
000005,A0000005,,
000006,A0000006,,
000007,A0000007,,
000008,A0000008,,
000009,A0000009,,
000010,A0000010,,
```

```erlang
alinkiot_csv:import_csv("device", "device.csv").
```
