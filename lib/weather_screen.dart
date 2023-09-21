import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

//import 'package:weather_app/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> currentWeather;
  String temperatureUnit = '°C';
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      String cityName = 'Mumbai';


      await dotenv.load();
      final openWeatherAPIkeyp = dotenv.env['OPEN_WEATHER_API_KEY'];

      final res = await http.get(
        Uri.parse('http://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIkeyp'),
      );
      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'An unexpected error occurred';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    currentWeather = getCurrentWeather();
  }

  void toggleTemperatureUnit() {
    setState(() {
      if (temperatureUnit == '°C') {
        temperatureUnit = '°F';
      } else {
        temperatureUnit = '°C';
      }
    });
  }

  double convertToCelsius(double temperature) {
    // convert to celsius
    temperature = temperature - 273.15;
    if (temperatureUnit == '°F') {
      return temperature * 9 / 5 + 32;
    }
    return temperature;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // make title center
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Weather App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Mumbai',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                currentWeather = getCurrentWeather();
              });
            },
            // add refresh icon
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: toggleTemperatureUnit, // Toggle temperature unit
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      body: FutureBuilder(
        future: currentWeather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          if (snapshot.hasError) {
            return Text(
              snapshot.error.toString(),
            );
          }

          final data = snapshot.data!;

          final currentWeatherData = data['list'][0];

          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final currentIcon = currentWeatherData['weather'][0]['icon'];
          final currentHumidity = currentWeatherData['main']['humidity'];
          final currentWindSpeed = currentWeatherData['wind']['speed'];
          final currentPressure = currentWeatherData['main']['pressure'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                '${convertToCelsius(currentTemp).toStringAsFixed(1)}$temperatureUnit',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Image.network('http://openweathermap.org/img/wn/$currentIcon@2x.png'),
                              Text(
                                currentSky,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                // Hourly Forecast
                const Text(
                  'Weather Forcast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),

                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final hourlyForecast = data['list'][index + 1];
                      final time = DateTime.parse(hourlyForecast['dt_txt']);
                      return HourlyForecastItem(
                        time: DateFormat.jm().format(time),
                        temperature: '${convertToCelsius(hourlyForecast['main']['temp']).toStringAsFixed(1)}$temperatureUnit',
                        iconUrl: 'http://openweathermap.org/img/wn/${hourlyForecast['weather'][0]['icon']}.png',
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                // Additional Information
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AdditionalInfoItem(icon: Icons.water_drop, label: 'Humidity', value: '$currentHumidity'),
                    AdditionalInfoItem(icon: Icons.air, label: 'Wind Speed', value: '$currentWindSpeed'),
                    AdditionalInfoItem(icon: Icons.beach_access, label: 'Pressure', value: '$currentPressure'),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
