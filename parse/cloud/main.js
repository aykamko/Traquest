Parse.Cloud.beforeSave('Tracking', function(request, response) {
  // Check if the user added a pin in the last minute
  var TrackingObject = 'Tracking';
  var query = new Parse.Query(TrackingObject);
	console.log();
  var oneMinuteAgo = new Date();
  oneMinuteAgo.setMinutes(oneMinuteAgo.getMinutes() - 1);
  query.greaterThan('createdAt', oneMinuteAgo);

  query.equalTo('user', Parse.User.current());

  // Count the number of pins
  query.count({
    success: function(count) {
      if (count > 0) {
        response.error('Sorry, too soon to post again!');
      } else {
        response.success();
      }
    },
    error: function(error) {
      response.error('Oups something went wrong.');
    }
  });
});

Parse.Cloud.define('deleteEventData', function(request,response) {
	var EventData = Parse.Object.extend('TrackingObject');
	var query = new Parse.Query(EventData);
	var eventIdKey = 'E' + request.params.eventId;
	query.find( {
		success: function(results) {
			console.log();
			if(results.length > 0) {
				for(var i=0; i< results.length; i++) {
					results[i].set(eventIdKey, "");
					results[i].save();
				}
			}
			response.success(results);
		},
		error: function(error) {
	      response.error('Oups something went wrong');
		}
	});
});

Parse.Cloud.define('getLocationAverage', function(request, response) {
  var LocationObject = Parse.Object.extend('Location');
  var query = new Parse.Query(LocationObject);

  query.equalTo('user', Parse.User.current());
  query.limit(100);
  query.find({
    success: function(results) {
      if (results.length > 0) {
        var longitudeSum = 0;
        var latitudeSum = 0;
        for (var i = 0; i < results.length; i++) {
          longitudeSum += results[i].get('location').longitude;
          latitudeSum += results[i].get('location').latitude;
        }
        var averageLocation = new Parse.GeoPoint(latitudeSum/results.length, longitudeSum/results.length);
        response.success(averageLocation);
      } else {
        response.error('Average not available');
      }
    },
    error: function(error) {
      response.error('Oups something went wrong');
    }
  });
});
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define('hello', function(request, response) {
	response.success(request.params.stuff);
	console.log();
});

