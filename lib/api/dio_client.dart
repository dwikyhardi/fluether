import 'package:dio/dio.dart';
import 'package:fluether/model/current_weather_data.dart';
import 'package:fluether/model/forecast_weather_data.dart';
import 'package:retrofit/retrofit.dart';

part 'dio_client.g.dart';

@RestApi(baseUrl: '')
abstract class DioClient {
  factory DioClient(Dio dio, {String baseUrl}) = _DioClient;

  @GET('weather')
  Future<CurrentWeatherData> getCurrentWeather(
    @Query('lat') double latitude,
    @Query('lon') double longitude,
    @Query('appid') String apiKey, {
    @Query('units') String unit = 'metric',
  });

  @GET('forecast')
  Future<ForecastWeatherData> getForecastWeather(
    @Query('lat') double latitude,
    @Query('lon') double longitude,
    @Query('appid') String apiKey, {
    @Query('units') String unit = 'metric',
    @Query('cnt') int cnt = 10,
  });
}
