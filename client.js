(function($) {
    $.QuickBase = function(options) {
        var defaults = {
            username: '',
            password: '',
            dbid: '',
            apptoken: '',
            realm: 'www.quickbase.com'      
        }

        var plugin = this;

        plugin.settings = {};
        plugin.payload = $('</qbdapi>');

        plugin.init = function(callback) {
            plugin.settings = $.extend({}, defaults, options);

            plugin.base_url = 'https://' + plugin.settings.realm + '/db/';

            if(typeof plugin.token === 'undefined') {
                plugin.authenticate(undefined, undefined, undefined, function(response) {
                    plugin.ticket = $(response).find('ticket').text();

                    return typeof(callback) == "function" ? callback() : this;
                });
            }
            else
                return typeof(callback) == "function" ? callback() : this;
        }

        $.QuickBase.record = function(o) {
            var record = $.extend({
                fid: '',
                name: '',
                value: '',
            }, o);

            try {
                if(record.fid === '' && record.name === '')
                    throw "Missing record fid or name.";

                if(record.value === '')
                    throw "Missing record value.";

                var id = record.fid !== '' ? 'fid="' + record.fid + '"' : 'name="' + record.name + '"';

                return '<field ' + id + '>' + record.value + '</field>';
            } catch (e) {
                console.log(e);
            }
        }

        function reset_payload() {
            plugin.payload = $('<qdbapi>');
            plugin.payload.append($('<ticket>').text(plugin.ticket));
            plugin.payload.append($('<apptoken>').text(plugin.settings.apptoken));        
        }

        function get_raw_xml(payload) {
            return $('<div/>').append(payload.clone()).html();
        }

        function QuickBaseException(action, errcode, errtext, errdetail) {
            this.action = action;
            this.errcode = errcode;
            this.errtext = errtext;
            this.errdetail = errdetail;
        }

        function showErrors(e) {
            console.log(e);
        }

        function transmit(action, payload, url, callback) {
            var url = (url === 'main') ? 
                    plugin.base_url + 'main' : 
                    plugin.base_url + plugin.settings.dbid;

            $.ajax({
                type: 'POST',
                beforeSend: function(request) {
                  request.setRequestHeader('QUICKBASE-ACTION', action);
                },
                url: url,
                data: get_raw_xml(payload),
                dataType: 'xml',
                contentType: 'text/xml',
                success: function(data, textStatus, jqXHR) {
                    var errcode = parseInt($(data).find('errcode').text());

                    try {
                        if(errcode > 0) {
                            var errtext = $(data).find('errtext').text(),
                                errdetail = $(data).find('errdetail').text();

                            throw new QuickBaseException(action, errcode, 
                                    errtext, errdetail);
                    }

                    reset_payload();

                    return typeof(callback) == "function" ? callback(data) : data;

                  } catch (e) {
                    showErrors(e);
                  }
                },
                error: function(xhr, ajaxOptions, thrownError) {
                  alert(xhr.status);
                  alert(thrownError);
                }
            });
        }

        plugin.authenticate = function(username, password, hours, callback) {
            var payload = $('<qdbapi>');

            if(typeof username === 'undefined')
                username = plugin.settings.username;

            if(typeof password === 'undefined')
                password = plugin.settings.password;

            if(typeof hours === 'undefined')
                hours = ''; // use QB default of 12 hours

            payload.append($('<username>').text(username));
            payload.append($('<password>').text(password));
            payload.append($('<hours>').text(hours));

            transmit('API_AUTHENTICATE', payload, 'main', callback);
        }

        plugin.get_schema = function(callback) {
            transmit('API_GetSchema', plugin.payload, 'db', function(data) {
                return typeof(callback) == "function" ? callback(data) : data;
            });
        }

        plugin.add_record = function(callback) {

        }

        plugin.edit_record = function(callback) {
            
        }

        plugin.do_query = function(query, options, callback) {
            var q = $('<qid>');

            if(isNaN(query)) {
                q = Boolean(query.match('^[{]')) ? $('<query>') : $('<qname>');
            }

            plugin.payload.append(q.text(query));

            for (var opt in options) {
                var opt_elem = '<' + opt + '>';
                plugin.payload.append($(opt_elem).text(options[opt]));
            }

            transmit('API_DoQuery', plugin.payload, 'db', function(data) {
                return typeof(callback) == "function" ? callback(data) : data;
            });
        }

        return this;
  }
}(jQuery));