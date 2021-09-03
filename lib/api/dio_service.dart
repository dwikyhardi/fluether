import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioService {
  static String apiKey = r'cff96ec320eea88f33e547cbe3503a54';
  static BuildContext? loadingContext;

  static Future<Dio> setupDio(
    BuildContext context, {
    bool isLoading = false,
  }) async {
    if (isLoading) {
      dialogLoading(context);
    }

    Dio dio = Dio();

    BaseOptions options = await _createBaseOption();

    dio = Dio(options);

    print('============= onRequest ============= ${dio.options.baseUrl}');

    DateTime responseTime = DateTime.now();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions? option, handler) async {
          responseTime = DateTime.now();
          print('============= onRequest =============');
          handler.next(option!);
        },
        onResponse: (Response response, handler) async {
          print('DateTime ${DateTime.now().toString()}');
          print(
              'responseTime ${DateTime.now().difference(responseTime).inMilliseconds}ms');
          print('method ${response.requestOptions.method}');
          print(
              'API ${response.requestOptions.uri.origin}${response.requestOptions.uri.path}');
          print('responseData ${response.data}');
          if (isLoading && loadingContext != null) {
            Navigator.pop(loadingContext!);
          }
          print('============= onResponse =============');
          handler.next(response);
        },
        onError: (DioError e, handler) async {
          print('DateTime ${DateTime.now().toString()}');
          print(
              'responseTime ${DateTime.now().difference(responseTime).inMilliseconds}ms');
          print('method ${e.requestOptions.method}');
          // print(
          //     'API ${e.requestOptions.uri.origin}${e.requestOptions.uri.path}');
          // print('responseData ${e.response}');
          print('============= onError =============');

          handler.next(e);
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        error: true,
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: true,
        compact: true,
        maxWidth: 500,
      ),
    );

    return dio;
  }

  static Future<BaseOptions> _createBaseOption() async {
    String baseUrl = r'https://api.openweathermap.org/data/2.5/';

    // if (isUseBearer) isUseBearer = await GlobalFunction.checkIsLogin();

    var options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30).inMilliseconds,
      receiveTimeout: Duration(seconds: 30).inMilliseconds,
      sendTimeout: Duration(seconds: 30).inMilliseconds,
    );
    return options;
  }

  static void dialogLoading(BuildContext context) => showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext buildContext) {
          loadingContext = buildContext;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                  Text(
                    r'Mohon Tunggu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
