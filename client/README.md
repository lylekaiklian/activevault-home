# Tasks

```
rake port_sweep
```
List ports where a GSM Dongle is connected.
```
rake dongle:number['COMX']
```
Display the mobile number of the Dongle in COM port X (e.g. COM4)

```
rake dongle:set_number['COMX','+63XXX']
```

```
rake dongle:balance['COMX']
```
```
rake dongle:send_message['COMX','+63XXX','Hello']
```