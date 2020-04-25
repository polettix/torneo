# API

The API will be modeled according to RESTful principles

## Structure

A prefix is implied and not considered.

```text
/torneos
/torneos/:tid
/torneos/:tid/status
/torneos/:tid/rounds/:rid/status
/torneos/:tid/rounds/:rid/matches/:mid/status
/torneos/:tid/rounds/:rid/matches/:mid/result
```

## Use cases

Here's a few ideas for the use cases

### Create New Tournament

POST to `/torneos`

### List Tournaments

GET to `/torneos`

### Get Tournament

GET to `/torneos/:tid`

### Open/Close Tournament

PUT to `/torneos/:tid`

### Open/Close Round

PUT to `/torneos/:tid/rounds/:rid`

### Open/Close Match

PUT to `/torneos/:tid/rounds/:rid/matches/:mid`

### Record Match Result

PUT to `/torneos/:tid/rounds/:rid/matches/:mid/result`
