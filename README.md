# QuickBase jQuery Plugin ![QuickBase Partner](http://i.imgur.com/tWX4YhU.png)

This project provides a jQuery-friendly alternative to the official [QuickBaseClient.js](http://www.quickbase.com/js/QuickBaseClient.js) offered by the Intuit QuickBase team for QuickBase customers building custom user interfaces within a dbpage that use the [QuickBase API](http://www.quickbase.com/api-guide/whnjs.htm).

But why? Doesn't QuickBase already have an official client?
----------
The official QuickBaseClient.js, as of today, was last updated in 10/3/2012. In addition to not being actively maintained, the library wasn't built using current javascript best-practices.

One fundamental issue that this project hopes to solve is that this plugin provides callbacks for all QuickBase API methods, providing developers with a fully asynchronous interface. With the current client, this is not supported and as a result, many QuickBase applications must set setTimeout or else the page can 'block' the user from performing specific actions while the API call returns.

##Usage
1. Include jQuery:

    ```html
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.0/jquery.min.js"></script>
	```

2. Include plugin's code:

	```html
	<script src="dist/jquery.quickbase.min.js"></script>
	```

3. Init the plugin:

    ```javascript
    var $qb = $.QuickBase({
		username: 'your_username',
		password: 'your_password',
		dbid: 'main_dbid',
		apptoken: 'app_token',
		realm: 'your-realm.quickbase.com'
	});
    ```

4. Go! (Adding a new record)
    ```javascript
    $qb.init(function() {
        // you are now authenticated
    	$qb.build_schema(function(schema) {
            // you now have a sweet obj representing your app
			window.app = schema;

            // change dbid to the table you wish to use
			$qb.settings.dbid = app.projects.dbid;

            // create an array of records to add to the projects table
			records = [
			    $qb.record(app.projects.fields.name.id, 'Sample Project'),
			    $qb.record(app.projects.fields.status.id, 'New'),
			    $qb.record(app.projects.fields.start_date.id, '10/1/2013'),
			    $qb.record(app.projects.fields.need_by_date.id, '10/1/2013'),
			    $qb.record(app.projects.fields.priority.id, 'Low'),
			    $qb.record(app.projects.fields.rating.id, 5),
			];

            // add record!
            $qb.add_record(records, function(response) {
			    console.log(response);
			});
        });
    });
    ```

## Testing Outside of QuickBase
Browser security limitations will normally prevent you from using this plugin outside of a QuickBase DBPage.

However, you can pass the --disable-web-security flag to Chrome and it will allow you to make cross-domain requests, effectively allowing you to test and dev in a local environment.

**Add this to your .bash_profile

```html
alias chrome-xss='open -a Google\ Chrome --args --disable-web-security --allow-file-access-from-files'
```

Launch chrome:

```javascript
chrome-xss
```

##Demos
A demo of how to add/edit/query records can be found in the /demo folder of the project.

Support
-----------
Contact Joshua McGinnis @ [joshua@mcginn.is](mailto:joshua@mcginn.is) or [BrookLab](http://www.brooklab.com).
