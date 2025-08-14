double convertToDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else if (value is String) {
    // Try to parse the string to a double, return 0.0 if unsuccessful
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  } else {
    return 0.0; // Default value for unsupported types
  }
}

int convertToInt(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else if (value is String) {
    // Try to parse the string to an integer, return 0 if unsuccessful
    try {
      return int.parse(value);
    } catch (e) {
      return 0;
    }
  } else {
    return 0; // Default value for unsupported types
  }
}

String convertToKMB(String value) {
  double doubleValue = double.tryParse(value) ?? 0.0;

  // Check if the value is negative
  bool isNegative = doubleValue < 0;

  // Take the absolute value for processing
  doubleValue = doubleValue.abs();

  if (doubleValue < 1000) {
    // Less than 1000, no conversion needed
    return (isNegative ? '-' : '') + doubleValue.toStringAsFixed(2);
  } else if (doubleValue < 1000000) {
    // Between 1000 and 1 million, convert to K
    double kValue = doubleValue / 1000;
    return (isNegative ? '-' : '') + '${kValue.toStringAsFixed(2)}K';
  } else if (doubleValue < 1000000000) {
    // Between 1 million and 1 billion, convert to M
    double mValue = doubleValue / 1000000;
    return (isNegative ? '-' : '') + '${mValue.toStringAsFixed(2)}M';
  } else if (doubleValue < 1000000000000) {
    // Between 1 billion and 1 trillion, convert to B
    double bValue = doubleValue / 1000000000;
    return (isNegative ? '-' : '') + '${bValue.toStringAsFixed(2)}B';
  } else if (doubleValue < 1000000000000000) {
    // Between 1 trillion and 1 quadrillion, convert to T
    double tValue = doubleValue / 1000000000000;
    return (isNegative ? '-' : '') + '${tValue.toStringAsFixed(2)}T';
  } else if (doubleValue < 1000000000000000000) {
    // Between 1 quadrillion and 1 quintillion, convert to Q
    double qValue = doubleValue / 1000000000000000;
    return (isNegative ? '-' : '') + '${qValue.toStringAsFixed(2)}Q';
  } else {
    // Above 1 quintillion, convert to Qi
    double qiValue = doubleValue / 1000000000000000000;
    return (isNegative ? '-' : '') + '${qiValue.toStringAsFixed(2)}Qi';
  }
}
