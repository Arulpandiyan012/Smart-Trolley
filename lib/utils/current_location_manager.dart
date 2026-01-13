class CurrentLocationManager {
  static String? address;
  static double? latitude;
  static double? longitude;
  
  // New Fields for API
  static String? city;
  static String? state;
  static String? country;
  static String? pincode;

  static void setLocation(String addr, double lat, double lng, 
      {String? cityVal, String? stateVal, String? countryVal, String? pinVal}) {
    address = addr;
    latitude = lat;
    longitude = lng;
    city = cityVal;
    state = stateVal;
    country = countryVal;
    pincode = pinVal;
  }
  
  static void clear() {
    address = null;
    latitude = null;
    longitude = null;
    city = null;
    state = null;
    country = null;
    pincode = null;
  }
}