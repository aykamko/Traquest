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
  var venueGeoPoint = request.params.venuGeoPoint;
  var venueLat = request.params.latitude;
  var venueLon = request.params.longitude;
  console.log(venueGeoPoint);

  var distanceDictionary = {latitude1: venueLat, longitude1: venueLon, latitude2: 0.0, longitude2: 0.0};
	var allowedUsers = new Array();

	Parse.Cloud.run('getUsers', {eventId: request.params.eventId, permission:'allowed'}, {
		success: function (allowed) {
      allowedUsers = allowed;

      Parse.Cloud.run('getUsers', {eventId: request.params.eventId, permission:'anonymous'}, {
        success: function (anonymous) {
          var totalUsers = allowedUsers.concat(anonymous);
          var numberAllowingTracking = totalUsers.length;

          var distancesFromLocation = new Array();
          var velocities = new Array();

          var sum = 0;
          var arrived = 0;
          var velocitySum = 0;
          var departed = 0;

          for (var i = 0; i < totalUsers.length; i++) {
            console.log(totalUsers[i].toJSON());
            var userStartPoint = (totalUsers[i].toJSON().locationData[0].location);
            var userCurrentPoint = (totalUsers[i].toJSON().locationData[1].location);

            var userStartTime = (totalUsers[i].toJSON().locationData[0]['time']);
            var timeElapsedInMinutes = (request.params.currentTime - userStartTime)/60;

            var userCurrentLat = userCurrentPoint.latitude;
            var userCurrentLon = userCurrentPoint.longitude;

            var userStartLat = userStartPoint.latitude;
            var userStartLon = userStartPoint.longitude;

            var distanceAtDeparture = findDistanceBetweenPoints(venueLat, venueLon, userStartLat, userStartLon);
            var distanceFromLocation = findDistanceBetweenPoints(venueLat, venueLon, userCurrentLat, userCurrentLon);

            var displacement = distanceAtDeparture - distanceFromLocation;

            var velocity = displacement/timeElapsedInMinutes;
            velocities.push(velocity);
            velocitySum = velocitySum + velocity;

            if (distanceFromLocation<0.5) {
              arrived++;
            }
            else if (displacement>0.5) {
              departed++;
            }

            distancesFromLocation.push(distanceFromLocation);
            sum = sum+distanceFromLocation;
          }

          distancesFromLocation.sort();

          if (distancesFromLocation.length>0) {
            var averageDistance = sum/distancesFromLocation.length;
            var averageVelocity = velocitySum/distancesFromLocation.length;
            var medianDistance;

            if (distancesFromLocation.length%2==1) {
               medianDistance = distancesFromLocation[Math.floor(distancesFromLocation.length/2)];
            } else{
              medianDistance = (distancesFromLocation[Math.floor(distancesFromLocation.length/2)] + distancesFromLocation[Math.floor(distancesFromLocation.length/2-1)])/2;
            }

            var timeUntilMedianArrives = medianDistance/averageVelocity;
            if (arrived>=numberAllowingTracking/2) {
              timeUntilMedianArrives = 0;
            }

            stats = 
            {"numberOfUsers": numberAllowingTracking, 
            "averageDistance": averageDistance,
            "medianDistance": medianDistance,
            "estimatedArrival": timeUntilMedianArrives,
            "averageVelocity" : averageVelocity*60,
            "numberArrived" : arrived,
            "numberDeparted" : departed};
          }

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
	
});

Parse.Cloud.define('demoStatistics', function(request, response){

  var stats;
  var venueGeoPoint = request.params.venuGeoPoint;
  var venueLat = request.params.latitude;
  var venueLon = request.params.longitude;
  console.log(venueGeoPoint);

  var distanceDictionary = {latitude1: venueLat, longitude1: venueLon, latitude2: 0.0, longitude2: 0.0};
  var allowedUsers = new Array();


  Parse.Cloud.run('getUsers', {eventId: request.params.eventId, permission:'DummyRelation'}, {
    success: function (anonymous) {
      console.log(anonymous);
      var totalUsers = allowedUsers.concat(anonymous);
      var numberAllowingTracking = totalUsers.length;

      var distancesFromLocation = new Array();
      var velocities = new Array();

      var sum = 0;
      var arrived = 0;
      var velocitySum = 0;
      var departed = 0;

      for (var i = 0; i < totalUsers.length; i++) {
        console.log(totalUsers[i].toJSON());
        var userStartPoint = (totalUsers[i].toJSON().locationData[0].location);
        var userCurrentPoint = (totalUsers[i].toJSON().locationData[1].location);

        var userStartTime = (totalUsers[i].toJSON().locationData[0]['time']);
        var timeElapsedInMinutes = (request.params.currentTime - userStartTime)/60;

        var userCurrentLat = userCurrentPoint.latitude;
        var userCurrentLon = userCurrentPoint.longitude;

        var userStartLat = userStartPoint.latitude;
        var userStartLon = userStartPoint.longitude;

        var distanceAtDeparture = findDistanceBetweenPoints(venueLat, venueLon, userStartLat, userStartLon);
        var distanceFromLocation = findDistanceBetweenPoints(venueLat, venueLon, userCurrentLat, userCurrentLon);

        var displacement = distanceAtDeparture - distanceFromLocation;
        var velocity = displacement/timeElapsedInMinutes;
        velocities.push(velocity);
        velocitySum = velocitySum + velocity;

        if (distanceFromLocation<0.5) {
          arrived++;
        }
        else if (displacement>0.5) {
          departed++;
        }

        distancesFromLocation.push(distanceFromLocation);
        sum = sum+distanceFromLocation;
      }

      distancesFromLocation.sort();

      if (distancesFromLocation.length>0) {
        var averageDistance = sum/distancesFromLocation.length;
        var averageVelocity = velocitySum/distancesFromLocation.length;
        var medianDistance;

        if (distancesFromLocation.length%2==1) {
           medianDistance = distancesFromLocation[Math.floor(distancesFromLocation.length/2)];
        } else{
          medianDistance = (distancesFromLocation[Math.floor(distancesFromLocation.length/2)] + distancesFromLocation[Math.floor(distancesFromLocation.length/2-1)])/2;
        }

        var timeUntilMedianArrives = medianDistance/averageVelocity;
        if (arrived>=numberAllowingTracking/2) {
          timeUntilMedianArrives = 0;
        }

        // comment

        stats = 
        {"numberOfUsers": numberAllowingTracking, 
        "averageDistance": averageDistance,
        "medianDistance": medianDistance,
        "estimatedArrival": timeUntilMedianArrives,
        "averageVelocity" : averageVelocity*60,
        "numberArrived" : arrived,
        "numberDeparted" : departed};
      }

      response.success(stats);
    },    
    error: function (error) {
      console.log(error);
      response.error('Error trying to find Anonymous Users');
    }
  });

});

var toRad = function(numberInDegrees) {
  return numberInDegrees * Math.PI / 180;
}



var findDistanceBetweenPoints = function (lat1, lon1, lat2, lon2) {

  // if (typeof(Number.prototype.toRad) === "undefined") {
  //   Number.prototype.toRad = function() {
  //     return this * Math.PI / 180;
  //   }
  // }

  var R = 3963; // km
  var dLat = toRad(lat2-lat1);
  var dLon = toRad(lon2-lon1);
  var lat1 = toRad(lat1);
  var lat2 = toRad(lat2);

  var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
          Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c;
  return d;
}

Parse.Cloud.define('getDistance', function(request, response) {
  // response.success(request.params.latitude2);
  var dist = findDistanceBetweenPoints(request.params.latitude1, request.params.longitude1, request.params.latitude2, request.params.longitude2);
  response.success(dist);
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
        console.log(fbEvent);
	      var relation = fbEvent.relation(request.params.permission);
	      relation.query().find().then(
			function (resultList) {
        console.log(resultList);
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

