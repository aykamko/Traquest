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

Parse.Cloud.define('calculateStatistics', function(request, response){
	var stats;
	var users = new Array();
	Parse.Cloud.run('getUsers', {eventId: request.params.eventId, permission:'allowed'}, {
		success: function (allowed) {
      users.concat(allowed);
      Parse.Cloud.run('getUsers', {eventId: request.params.eventId, permission:'anonymous'}, {
        success: function (anonymous) {
          users.concat(anonymous);
          stats.totalNumberOfUsers = users.length;
          response.success(stats);
        },    
        error: function (error) {
          console.log(error);
          response.error('Error trying to find Anonymous Users');
        }
      });
    },
    error: function (error) {
      console.log(error);
      response.error('Error trying to find Allowed Users');
    }
	});
	
	/*var R = 6371; // km
	var dLat = (lat2-lat1).toRad();
	var dLon = (lon2-lon1).toRad();
	var lat1 = lat1.toRad();
	var lat2 = lat2.toRad();

	var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
	        Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
	var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
	var d = R * c;*/
});

Parse.Cloud.define('deleteEventData', function(request, response) {
  Parse.Cloud.run('deleteAllowedUsers', { eventId: request.params.eventId }, {
    success: function (result) {
      console.log(result);
      Parse.Cloud.run('deleteAnonymousUsers', { eventId: request.params.eventId }, {
        success: function (result) {
          response.success(result);
        },
        error: function (error) {
          console.log(error);
          response.error('Error trying to run "deleteAnonymousUsers" function');
        }
      });
    },
    error: function (error) {
      console.log(error);
      response.error('Error trying to run "deleteAllowedUsers" function');
    }
  });
});

Parse.Cloud.define('getUsers', function(request,response){
	var Event = Parse.Object.extend("Event");
	var eventQuery = new Parse.Query(Event);
	eventQuery.equalTo("eventId", request.params.eventId);
	eventQuery.first({
	    success: function(fbEvent) {
	      var relation = fbEvent.relation(request.params.permission);
	      relation.query().find().then(
			function (resultList) {
			response.success(resultList);
			},
			function (badResult) {
			      response.error("Error retreiving objects in allowed relation!");
			});
		},
		error: function(error) {
			response.error('Error querying for event');
		}
    }); 
});

Parse.Cloud.define('deleteAllowedUsers', function(request, response) {
  var Event = Parse.Object.extend("Event");
  var eventQuery = new Parse.Query(Event);
  eventQuery.equalTo("eventId", request.params.eventId);
  eventQuery.first({
    success: function(fbEvent) {
      var relation = fbEvent.relation("allowed");
      relation.query().find().then(
        function (resultList) {

          console.log(resultList);
          if (resultList.length > 0) {
            relation.remove(resultList);
          }

          fbEvent.save().then(
            function (successfulSave) {
              response.success(successfulSave);
            },
            function (badSave) {
              console.log(badSave);
              response.error("Error saving after deleting objects in allowed relation!");
            });

        },
        function (badResult) {
          response.error("Error retreiving objects in allowed relation!");
        });
    },
    error: function (error) {
      console.log(error);
      response.error('Error querying for event!');
    }
  });
});

Parse.Cloud.define('deleteAnonymousUsers', function(request, response) {
  var Event = Parse.Object.extend("Event");
  var eventQuery = new Parse.Query(Event);
  eventQuery.equalTo("eventId", request.params.eventId);
  eventQuery.first({
    success: function(fbEvent) {
      var relation = fbEvent.relation("anonymous");
      relation.query().find().then(
        function (resultList) {

          console.log(resultList);
          if (resultList.length > 0) {
            relation.remove(resultList);
          }

          fbEvent.save().then(
            function (successfulSave) {
              response.success(successfulSave);
            },
            function (badSave) {
              console.log(badSave);
              response.error("Error saving after deleting objects in anonymous relation!");
            });

        },
        function (badResult) {
          response.error("Error retreiving objects in anonymous relation!");
        });
    },
    error: function (error) {
      console.log(error);
      response.error('Error querying for event!');
    }
  });
});

Parse.Cloud.define('disallowOldEvents', function(request, response) {
	var eventDate = request.params.date;
	var UserObject = Parse.User;
	var userQuery = new Parse.Query(UserObject);
	userQuery.equalTo('fbID', request.params.fbID);
	userQuery.first({
		success: function(user) {
			user.set('dateTracked',eventDate);
			user.save();
			console.log(user.toJSON());
			response.success(user);
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

