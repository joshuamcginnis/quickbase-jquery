(($) ->
  $.QuickBase = (options) ->
    reset_payload = ->
      plugin.payload = $("<qdbapi>")
      plugin.payload.append $("<ticket>").text(plugin.ticket)
      plugin.payload.append $("<apptoken>").text(plugin.settings.apptoken)
    get_raw_xml = (payload) ->
      $("<div/>").append(payload.clone()).html()
    QuickBaseException = (action, errcode, errtext, errdetail) ->
      @action = action
      @errcode = errcode
      @errtext = errtext
      @errdetail = errdetail
    handle_errors = (e) ->
      console.log e
      console.log e.message
    add_options_to_payload = (options) ->
      prop = undefined
      opt = undefined
      if options
        for prop of options
          opt = "<" + prop + ">"
          plugin.payload.append $(opt).text(options[prop])
    transmit = (action, payload, url, callback) ->
      url = (if (url is "main") then plugin.base_url + "main" else plugin.base_url + plugin.settings.dbid)
      $.ajax
        type: "POST"
        beforeSend: (request) ->
          request.setRequestHeader "QUICKBASE-ACTION", action

        url: url
        data: get_raw_xml(payload)
        dataType: "xml"
        contentType: "text/xml"
        success: (data) ->
          errcode = parseInt($(data).find("errcode").text(), 10)
          errtext = undefined
          errdetail = undefined
          try
            if errcode > 0
              errtext = $(data).find("errtext").text()
              errdetail = $(data).find("errdetail").text()

              throw new QuickBaseException(action, errcode, errtext, errdetail)
            reset_payload()
            return (if typeof (callback) is "function" then callback(data) else data)
          catch e
            handle_errors e

        error: (xhr, ajaxOptions, thrownError) ->
          console.log xhr
          console.log ajaxOptions
          console.log thrownError

    defaults =
      username: ""
      password: ""
      dbid: ""
      apptoken: ""
      realm: "www.quickbase.com"

    plugin = this
    plugin.settings = {}
    plugin.payload = $("</qbdapi>")
    plugin.init = (callback) ->
      plugin.settings = $.extend({}, defaults, options)
      plugin.base_url = "https://" + plugin.settings.realm + "/db/"
      if typeof plugin.token is "undefined"
        plugin.authenticate `undefined`, `undefined`, `undefined`, (response) ->
          plugin.ticket = $(response).find("ticket").text()
          (if typeof (callback) is "function" then callback() else this)

      else
        (if typeof (callback) is "function" then callback() else this)

    plugin.record = (fid, value) ->
      id = (if isNaN(fid) then "name=\"" + fid + "\"" else "fid=\"" + fid + "\"")
      "<field " + id + ">" + value + "</field>"

    plugin.authenticate = (username, password, hours, callback) ->
      payload = $("<qdbapi>")
      username = plugin.settings.username  if typeof username is "undefined"
      password = plugin.settings.password  if typeof password is "undefined"
      hours = ""  if typeof hours is "undefined" # use QB default of 12 hours
      payload.append $("<username>").text(username)
      payload.append $("<password>").text(password)
      payload.append $("<hours>").text(hours)
      transmit "API_AUTHENTICATE", payload, "main", callback

    plugin.build_schema = (callback) ->
      schema = {}
      transmit "API_GetSchema", plugin.payload, "db", (data) ->
        build_schema_obj = (index) ->
          $fields = undefined
          $queries = undefined
          f = undefined
          q = undefined
          plugin.settings.dbid = $($chdbids[index]).text()
          if index + 1 > $chdbids.length
            (if typeof (callback) is "function" then callback(schema) else schema)
          else
            plugin.get_schema (data) ->
              build_fields_obj = (i) ->
                i = i or 0
                if i + 1 > $fields.length
                  $.extend schema[table_name], f
                  false
                else
                  $field = $($fields[i])
                  field_label_raw = $field.find("label").text()
                  field_label = field_label_raw.toLowerCase().replace(/\W/g, "_")
                  field_id = $field.attr("id")
                  field_type = $field.attr("field_type")
                  f.fields[field_label] =
                    id: field_id
                    label: field_label_raw
                    field_type: field_type

                  build_fields_obj i + 1
              build_queries_obj = (i) ->
                i = i or 0
                if i + 1 > $queries.length
                  $.extend schema[table_name], q
                  false
                else
                  $query = $($queries[i])
                  query_id = $query.attr("id")
                  query_name_raw = $query.find("qyname").text()
                  query_name = query_name_raw.toLowerCase().replace(/\W/g, "_")

                  q.queries[query_name] =
                    id: query_id
                    name: query_name_raw

                  build_queries_obj i + 1
              $chdbid = $($chdbids[index])
              dbid = $chdbid.text()
              table_name = $chdbid.attr("name").substring("_dbid_".length)
              schema[table_name] = dbid: dbid
              $fields = $(data).find("field")
              f = fields: {}

              build_fields_obj()  if $fields.length
              $queries = $(data).find("query")
              q = queries: {}

              build_queries_obj()  if $queries.length
              build_schema_obj index + 1

        try
          $chdbids = $(data).find("chdbid")
          throw "This operation requires a parent-level DBID."  if $chdbids.length is 0
        catch e
          handleErrors e
        build_schema_obj 0


    plugin.get_schema = (callback) ->
      transmit "API_GetSchema", plugin.payload, "db", (data) ->
        (if typeof (callback) is "function" then callback(data) else data)


    plugin.add_record = (records, options, callback) ->
      if $.isFunction(options)
        callback = options
        options = `undefined`
      add_options_to_payload options
      $.each records, (index, value) ->
        plugin.payload.append $(value)

      transmit "API_AddRecord", plugin.payload, "db", (data) ->
        (if typeof (callback) is "function" then callback(data) else data)


    plugin.delete_record = (rid, options, callback) ->
      if $.isFunction(options)
        callback = options
        options = `undefined`
      add_options_to_payload options
      plugin.payload.append "<rid>" + rid + "</rid>"
      transmit "API_DeleteRecord", plugin.payload, "db", (data) ->
        (if typeof (callback) is "function" then callback(data) else data)


    plugin.do_query = (query, options, callback) ->
      q = $("<qid>")
      prop = undefined
      opt = undefined
      q = (if Boolean(query.match("^[{]")) then $("<query>") else $("<qname>"))  if isNaN(query)
      plugin.payload.append q.text(query)
      for prop of options
        opt = "<" + prop + ">"
        plugin.payload.append $(opt).text(options[prop])
      transmit "API_DoQuery", plugin.payload, "db", (data) ->
        (if typeof (callback) is "function" then callback(data) else data)


    plugin.edit_record = (rid, fields, options, callback) ->
      if $.isFunction(options)
        callback = options
        options = `undefined`
      add_options_to_payload options
      plugin.payload.append "<rid>" + rid + "</rid>"
      $.each fields, (index, value) ->
        plugin.payload.append $(value)

      transmit "API_EditRecord", plugin.payload, "db", (data) ->
        (if typeof (callback) is "function" then callback(data) else data)


    plugin.sign_out = (udata, callback) ->
      if $.isFunction(udata)
        callback = udata
        udata = `undefined`
      plugin.payload.append "<udata>" + udata + "</udata>"  if udata
      transmit "API_SignOut", plugin.payload, "main", (data) ->
        (if typeof (callback) is "function" then callback(data) else data)


    this
) jQuery
