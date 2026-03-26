import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CropYieldApp());
}

class CropYieldApp extends StatelessWidget {
  const CropYieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Yield Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F8E9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFA5D6A7), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          labelStyle: const TextStyle(color: Color(0xFF558B2F), fontSize: 13),
          hintStyle:
              const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API base URL — replace with your Render URL when deployed
// ─────────────────────────────────────────────────────────────────────────────
const String _apiBaseUrl = 'https://linearregressionmodel-production-548a.up.railway.app/docs';

// ─────────────────────────────────────────────────────────────────────────────
// Data constants
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _countries = [
  'Angola', 'Burkina Faso', 'Cameroon', 'Ethiopia', 'Ghana',
  'Guinea', 'Kenya', 'Malawi', 'Mali', 'Mozambique',
  'Niger', 'Nigeria', 'Rwanda', 'Senegal', 'Tanzania',
  'Uganda', 'Zambia', 'Zimbabwe',
];

const List<String> _crops = [
  'Beans', 'Cassava', 'Groundnuts', 'Maize', 'Millet',
  'Plantains', 'Rice', 'Sorghum', 'Sweet potatoes', 'Yams',
];

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();

  // Dropdown selections
  String? _selectedCountry;
  String? _selectedCrop;

  // Text controllers — one per numeric field (12 fields)
  final _yearCtrl               = TextEditingController();
  final _rainfallCtrl           = TextEditingController();
  final _tempCtrl               = TextEditingController();
  final _humidityCtrl           = TextEditingController();
  final _pesticidesCtrl         = TextEditingController();
  final _fertilizerCtrl         = TextEditingController();
  final _arableCtrl             = TextEditingController();
  final _soilCtrl               = TextEditingController();
  final _irrigationCtrl         = TextEditingController();
  final _gdpCtrl                = TextEditingController();
  final _ruralCtrl              = TextEditingController();
  final _co2Ctrl                = TextEditingController();

  // State
  bool    _isLoading  = false;
  String? _resultText;
  bool    _isError    = false;

  @override
  void dispose() {
    for (final c in [
      _yearCtrl, _rainfallCtrl, _tempCtrl, _humidityCtrl,
      _pesticidesCtrl, _fertilizerCtrl, _arableCtrl, _soilCtrl,
      _irrigationCtrl, _gdpCtrl, _ruralCtrl, _co2Ctrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Validation helpers ─────────────────────────────────────────────────────
  String? _intRange(String? v, int min, int max) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Enter a whole number';
    if (n < min || n > max) return 'Must be $min – $max';
    return null;
  }

  String? _floatRange(String? v, double min, double max) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a number';
    if (n < min || n > max) return 'Must be $min – $max';
    return null;
  }

  // ── API call ───────────────────────────────────────────────────────────────
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _resultText = 'Please fix the errors above before predicting.';
        _isError    = true;
      });
      return;
    }

    setState(() {
      _isLoading  = true;
      _resultText = null;
      _isError    = false;
    });

    final body = jsonEncode({
      'country':                        _selectedCountry,
      'crop':                           _selectedCrop,
      'year':                           int.parse(_yearCtrl.text.trim()),
      'average_rain_fall_mm_per_year':  double.parse(_rainfallCtrl.text.trim()),
      'avg_temp':                       double.parse(_tempCtrl.text.trim()),
      'humidity_pct':                   double.parse(_humidityCtrl.text.trim()),
      'pesticides_tonnes':              double.parse(_pesticidesCtrl.text.trim()),
      'fertilizer_kg_ha':               double.parse(_fertilizerCtrl.text.trim()),
      'arable_land_pct':                double.parse(_arableCtrl.text.trim()),
      'soil_quality_index':             double.parse(_soilCtrl.text.trim()),
      'irrigation_coverage_pct':        double.parse(_irrigationCtrl.text.trim()),
      'gdp_per_capita_usd':             double.parse(_gdpCtrl.text.trim()),
      'rural_population_pct':           double.parse(_ruralCtrl.text.trim()),
      'co2_emissions_metric_tons':      double.parse(_co2Ctrl.text.trim()),
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hgHa = data['predicted_yield_hg_ha'];
        final kgHa = data['predicted_yield_kg_ha'];
        final tHa  = data['predicted_yield_t_ha'];
        final mdl  = data['model_used'];
        setState(() {
          _isError    = false;
          _resultText =
              '${data['country']} · ${data['crop']}\n\n'
              '${_fmt(hgHa)}  hg/ha\n'
              '${_fmt(kgHa)}  kg/ha\n'
              '${_fmt(tHa, decimals: 4)}  t/ha\n\n'
              'Model: $mdl';
        });
      } else {
        final data  = jsonDecode(response.body);
        final detail = data['detail'] ?? 'Unknown error';
        setState(() {
          _isError    = true;
          _resultText = 'Error ${response.statusCode}: $detail';
        });
      }
    } catch (e) {
      setState(() {
        _isError    = true;
        _resultText = 'Connection error: Could not reach the API.\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _fmt(dynamic v, {int decimals = 2}) =>
      (v as num).toStringAsFixed(decimals);

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌾', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Crop Yield Predictor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            width: double.infinity,
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: const Text(
              'Sub-Saharan Africa · FAO STAT Data · 18 Countries',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 11.5),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Section: Location & Crop ──────────────────────────────────
              _sectionHeader('📍 Location & Crop', 'Select country and crop type'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DropdownField(
                      label: 'Country',
                      hint: 'Select country',
                      items: _countries,
                      value: _selectedCountry,
                      onChanged: (v) => setState(() => _selectedCountry = v),
                      validator: (v) =>
                          v == null ? 'Please select a country' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DropdownField(
                      label: 'Crop Type',
                      hint: 'Select crop',
                      items: _crops,
                      value: _selectedCrop,
                      onChanged: (v) => setState(() => _selectedCrop = v),
                      validator: (v) =>
                          v == null ? 'Please select a crop' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: _yearCtrl,
                label: 'Year',
                hint: 'e.g. 2010',
                suffix: '',
                keyboard: TextInputType.number,
                validator: (v) => _intRange(v, 1990, 2030),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              // ── Section: Climate ──────────────────────────────────────────
              const SizedBox(height: 20),
              _sectionHeader('🌦️ Climate Conditions', 'Annual weather data'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _rainfallCtrl,
                      label: 'Annual Rainfall',
                      hint: '50 – 3000',
                      suffix: 'mm/yr',
                      validator: (v) => _floatRange(v, 50, 3000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _tempCtrl,
                      label: 'Avg Temperature',
                      hint: '10 – 40',
                      suffix: '°C',
                      validator: (v) => _floatRange(v, 10, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: _humidityCtrl,
                label: 'Relative Humidity',
                hint: '10 – 100',
                suffix: '%',
                validator: (v) => _floatRange(v, 10, 100),
              ),

              // ── Section: Agricultural Inputs ──────────────────────────────
              const SizedBox(height: 20),
              _sectionHeader('🚜 Agricultural Inputs', 'Farming resources applied'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _pesticidesCtrl,
                      label: 'Pesticides',
                      hint: '0 – 500',
                      suffix: 'tonnes',
                      validator: (v) => _floatRange(v, 0, 500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _fertilizerCtrl,
                      label: 'Fertilizer',
                      hint: '0 – 500',
                      suffix: 'kg/ha',
                      validator: (v) => _floatRange(v, 0, 500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _arableCtrl,
                      label: 'Arable Land',
                      hint: '1 – 90',
                      suffix: '%',
                      validator: (v) => _floatRange(v, 1, 90),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _irrigationCtrl,
                      label: 'Irrigation Coverage',
                      hint: '0 – 100',
                      suffix: '%',
                      validator: (v) => _floatRange(v, 0, 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: _soilCtrl,
                label: 'Soil Quality Index',
                hint: '0 – 100',
                suffix: 'score',
                validator: (v) => _floatRange(v, 0, 100),
              ),

              // ── Section: Socioeconomic ────────────────────────────────────
              const SizedBox(height: 20),
              _sectionHeader('📊 Socioeconomic Factors', 'Country-level indicators'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _gdpCtrl,
                      label: 'GDP per Capita',
                      hint: '100 – 20000',
                      suffix: 'USD',
                      validator: (v) => _floatRange(v, 100, 20000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _ruralCtrl,
                      label: 'Rural Population',
                      hint: '10 – 100',
                      suffix: '%',
                      validator: (v) => _floatRange(v, 10, 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: _co2Ctrl,
                label: 'CO₂ Emissions',
                hint: '0 – 5',
                suffix: 'metric t/capita',
                validator: (v) => _floatRange(v, 0, 5),
              ),

              // ── Predict button ────────────────────────────────────────────
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF81C784),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.agriculture_rounded, size: 22),
                  label: Text(
                    _isLoading ? 'Predicting...' : 'Predict',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ── Result display ────────────────────────────────────────────
              if (_resultText != null) ...[
                const SizedBox(height: 20),
                _ResultCard(text: _resultText!, isError: _isError),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header widget ──────────────────────────────────────────────────
  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 4),
        Container(height: 1.5, color: const Color(0xFFC8E6C9)),
      ],
    );
  }

  // ── Numeric text field builder ─────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required String? Function(String?) validator,
    TextInputType keyboard = const TextInputType.numberWithOptions(decimal: true),
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters ??
            [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: Color(0xFF558B2F),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown field widget
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?) validator;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: hint),
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: Color(0xFF212121)),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result card widget
// ─────────────────────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final String text;
  final bool isError;

  const _ResultCard({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final bg     = isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final border = isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32);
    final icon   = isError ? Icons.error_outline_rounded
                           : Icons.check_circle_outline_rounded;
    final title  = isError ? 'Prediction Error' : 'Predicted Crop Yield';

    // Parse yield lines for bold display (only when success)
    final lines = text.split('\n');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(icon, color: border, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isError)
            Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFC62828)))
          else ...[
            // Country · Crop line
            if (lines.isNotEmpty)
              Text(
                lines[0],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF388E3C),
                ),
              ),
            const SizedBox(height: 10),
            // Yield values
            ...lines.skip(1).where((l) => l.contains('hg/ha') || l.contains('kg/ha') || l.contains('t/ha')).map(
              (line) {
                final parts = line.trim().split('  ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        parts.isNotEmpty ? parts[0] : '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        parts.length > 1 ? parts[1] : '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF558B2F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Model line
            ...lines.where((l) => l.startsWith('Model:')).map(
              (line) => Text(
                line,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF757575),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
