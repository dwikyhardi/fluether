import 'dart:async';
import 'dart:convert';

import 'package:fluether/api/dio_client.dart';
import 'package:fluether/api/dio_service.dart';
import 'package:fluether/model/current_weather_data.dart';
import 'package:fluether/model/forecast_weather_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'
    as permissionHandler;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CurrentWeatherData? _currentWeatherData;
  ForecastWeatherData? _forecastWeatherData;

  Future<Position?> getLatLong() async {
    Position positionZero = Position(
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      timestamp: DateTime.now(),
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    bool isGpsEnabled =
        await permissionHandler.Permission.location.serviceStatus.isEnabled;
    LocationPermission locationPermission = await Geolocator.checkPermission();
    // var locationPermissionStatus =
    //     await LocationPermissions().checkPermissionStatus();
    var locationStatus = await permissionHandler.Permission.location.status;
    Position? currentPosition;
    if (!isGpsEnabled) {
      showCupertinoDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CupertinoAlertDialog(
              title: Text('We need to access your location'),
              content: Text(
                  'Fluether need your location for improving weather data in your current area'),
            );
          }).then((_) {
        print('permission Denied');
      });
      return Future.error('error');
    } else if (
        // locationPermissionStatus == PermissionStatus.granted ||
        locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse) {
      currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              forceAndroidLocationManager: true,
              timeLimit: Duration(seconds: 5))
          .catchError((e) async {
        print('TimeOut => error boy');
        FutureOr<Position> pos = (await Geolocator.getLastKnownPosition(
                    forceAndroidLocationManager: true)
                .timeout(Duration(seconds: 5), onTimeout: () {
              print('TimeOutLagi => error lagi boy');
              return positionZero;
            })) ??
            positionZero;
        return pos;
      });

      print('Try location handphone  ${currentPosition.toString()}');

      return currentPosition;
    } else {
      if (locationStatus ==
              permissionHandler.PermissionStatus.permanentlyDenied ||
          locationStatus == permissionHandler.PermissionStatus.restricted) {
        showCupertinoDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CupertinoAlertDialog(
                title: Text('We need to access your location'),
                content: Text(
                    'Fluether need your location for improving weather data in your current area'),
              );
            }).then((_) {
          print('permission Denied');
        });
      } else {
        await permissionHandler.Permission.location
            .request()
            .then((value) async {
          print('permissionHandler.PermissionStatus ${value.toString()}');
        });
      }
      return Future.value(getLatLong());
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLatLong().then((position) {
      getCurrentWeather(position!).then((value) {
        getForecastWeather(position);
      });
    });
  }

  Future<void> getCurrentWeather(Position position) async {
    await DioService.setupDio(context, isLoading: true).then((dio) async {
      var currentWeather = await DioClient(dio).getCurrentWeather(
          position.latitude, position.longitude, DioService.apiKey);

      print('Current Weather =>>>>>> ${jsonEncode(currentWeather)}');
      setState(() {
        _currentWeatherData = currentWeather;
      });
    });
  }

  Future<void> getForecastWeather(Position position) async {
    await DioService.setupDio(context, isLoading: true).then((dio) async {
      var forecastWeather = await DioClient(dio).getForecastWeather(
          position.latitude, position.longitude, DioService.apiKey);

      print('Forecast Weather =>>>>>> ${jsonEncode(forecastWeather)}');
      setState(() {
        _forecastWeatherData = forecastWeather;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Container(
        height: height,
        child: Stack(
          children: [
            _imageHeader(),
            _createCard(height, width),
          ],
        ),
      ),
    );
  }

  Image _imageHeader() {
    var image = 'assets/images/afternoon.png';
    var curDate = DateTime.fromMillisecondsSinceEpoch(
        (_currentWeatherData?.dt ?? DateTime.now().millisecondsSinceEpoch) *
            1000);
    var sunrise = DateTime.fromMillisecondsSinceEpoch(
        (_currentWeatherData?.sys?.sunrise ??
                DateTime.now().millisecondsSinceEpoch) *
            1000);
    var sunset = DateTime.fromMillisecondsSinceEpoch(
        (_currentWeatherData?.sys?.sunset ??
                DateTime.now().millisecondsSinceEpoch) *
            1000);
    print(curDate.toString());
    print(sunrise.toString());
    print(sunset.toString());
    if (curDate.isAfter(sunrise) && curDate.isBefore(sunset)) {
      image = 'assets/images/afternoon.png';
    } else if (curDate.isBefore(sunrise)) {
      image = 'assets/images/night.png';
    }
    return Image.asset(
      image,
    );
  }

  Positioned _createCard(double height, double width) {
    var format = DateFormat('EE, dd MMM yyyy - kk:mm');
    var curDate = format.format(DateTime.fromMillisecondsSinceEpoch(
        (_currentWeatherData?.dt ?? DateTime.now().millisecondsSinceEpoch) *
            1000));
    return Positioned(
      bottom: 0,
      child: Card(
        elevation: 10,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SizedBox(
          height: height - 225,
          width: width,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                _locationInfo(),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      _currentWeather(height),
                      SizedBox(
                        height: 20,
                      ),
                      _currentWind(height),
                      SizedBox(
                        height: 20,
                      ),
                      _astronomyInfo(height),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        height: 125,
                        width: width,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                                _forecastWeatherData?.listWeather?.length ?? 0,
                            scrollDirection: Axis.horizontal,
                            itemBuilder:
                                (BuildContext buildContext, int index) {
                              var formatForecast = DateFormat('EE, dd');
                              var formatForecastTime = DateFormat('kk:mm');
                              var data =
                                  _forecastWeatherData?.listWeather?[index];
                              print('data ${jsonEncode(data)}');
                              var iconUrl =
                                  "https://openweathermap.org/img/w/${data?.weather?.first?.icon ?? "10d"}.png";
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 5),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        iconUrl,
                                        height: height * 0.05,
                                      ),
                                      Text(
                                        formatForecast.format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                (data?.dt ?? 0) * 1000)),
                                      ),
                                      Text(
                                        formatForecastTime.format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                (data?.dt ?? 0) * 1000)),
                                      ),
                                      Row(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                _currentWeatherData
                                                        ?.main?.tempMax
                                                        .toString() ??
                                                    '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                '˚',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'C',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w100,
                                                  color: Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Image.asset(
                                                'assets/icons/arrow_upward.png',
                                                height: height * 0.02,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                _currentWeatherData
                                                        ?.main?.tempMin
                                                        .toString() ??
                                                    '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                '˚',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'C',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w100,
                                                  color: Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Image.asset(
                                                'assets/icons/arrow_down.png',
                                                height: height * 0.02,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row _astronomyInfo(double height) {
    var format = DateFormat('kk:mm');
    var sunriseTime = DateTime.fromMillisecondsSinceEpoch(
        ((_currentWeatherData?.sys?.sunrise ??
                DateTime.now().millisecondsSinceEpoch) *
            1000));
    var sunsetTime = DateTime.fromMillisecondsSinceEpoch(
        (_currentWeatherData?.sys?.sunset ??
                DateTime.now().millisecondsSinceEpoch) *
            1000);
    var daytimeSplit = sunsetTime.difference(sunriseTime).toString().split(':');
    var daytime = '${daytimeSplit[0]}h ${daytimeSplit[1]}m';
    print(sunsetTime.difference(sunriseTime).toString());
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/sunrise.png',
              height: height * 0.07,
              color: Colors.grey,
            ),
            Text(
              format.format(sunriseTime),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Sunrise',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/sunset.png',
              height: height * 0.07,
              color: Colors.grey,
            ),
            Text(
              format.format(sunsetTime),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Sunset',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/daytime.png',
              height: height * 0.07,
              color: Colors.grey,
            ),
            Text(
              daytime,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Daytime',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row _currentWind(double height) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/humidity.png',
              height: height * 0.07,
              color: Colors.grey,
            ),
            Text(
              '${_currentWeatherData?.main?.humidity ?? 0}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Humidity',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/gauge.png',
              height: height * 0.07,
              color: Colors.grey,
            ),
            Text(
              '${_currentWeatherData?.main?.pressure}mBar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Pressure',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/wind.png',
              height: height * 0.07,
              color: Colors.grey,
            ),
            Text(
              '${_currentWeatherData?.wind?.speed}km/h',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            Text(
              'Wind',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row _currentWeather(double height) {
    var iconUrl =
        "https://openweathermap.org/img/w/${_currentWeatherData?.weather?.first?.icon ?? "10d"}.png";
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Image.network(
              iconUrl,
              height: height * 0.09,
            ),
            Text(
              '${_currentWeatherData?.weather?.first?.main ?? ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              _currentWeatherData?.main?.temp.toString() ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontSize: 36,
              ),
            ),
            Text(
              '˚',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 26,
              ),
            ),
            Text(
              'C',
              style: TextStyle(
                fontWeight: FontWeight.w100,
                color: Colors.grey,
                fontSize: 26,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _currentWeatherData?.main?.tempMax.toString() ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '˚',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'C',
                  style: TextStyle(
                    fontWeight: FontWeight.w100,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Image.asset(
                  'assets/icons/arrow_upward.png',
                  height: height * 0.02,
                  color: Colors.grey,
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _currentWeatherData?.main?.tempMin.toString() ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '˚',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'C',
                  style: TextStyle(
                    fontWeight: FontWeight.w100,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Image.asset(
                  'assets/icons/arrow_down.png',
                  height: height * 0.02,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Positioned _locationInfo() {
    return Positioned(
      right: 0.0,
      top: 0.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
          color: Colors.blue[50],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_currentWeatherData?.name ?? ''}, ${_currentWeatherData?.sys?.country ?? ''}',
              style: TextStyle(
                  color: Colors.blue[300], fontWeight: FontWeight.bold),
            ),
            Icon(
              Icons.location_on_sharp,
              color: Colors.blue[300],
            ),
          ],
        ),
      ),
    );
  }
}
