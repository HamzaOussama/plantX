import React, { useState, useEffect } from 'react';
import { Cloud, Droplets, Thermometer, Wind, Zap, Send, AlertCircle } from 'lucide-react';
import axios from 'axios';

export default function IoTDashboard() {
  // Configure your API Gateway URLs here
  const API_URL = 'https://0j4pn0nhra.execute-api.us-east-1.amazonaws.com/dev/';
  const COMMANDS_API = 'https://0j4pn0nhra.execute-api.us-east-1.amazonaws.com/dev/commands';

  const [sensorData, setSensorData] = useState({
    soil_moisture: 0,
    temperature: 0,
    humidity: 0,
    light_intensity: 0,
    battery_level: 100,
    timestamp: new Date().toLocaleTimeString()
  });

  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(false);
  const [alerts, setAlerts] = useState([]);
  const [commandStatus, setCommandStatus] = useState('');
  const [connectionStatus, setConnectionStatus] = useState('Connecting...');
  const [lastUpdate, setLastUpdate] = useState(null);
  const [autoWateringEnabled, setAutoWateringEnabled] = useState(false);

  // Fetch real sensor data from AWS Lambda via API Gateway
  const fetchSensorData = async () => {
    try {
      console.log('Fetching from:', API_URL);
      const response = await axios.get(API_URL);
      console.log('Response:', response.data);
      
      const data = response.data;
      
      setSensorData({
        soil_moisture: parseFloat(data.soil_moisture) || 0,
        temperature: parseFloat(data.temperature) || 0,
        humidity: parseFloat(data.humidity) || 0,
        light_intensity: parseFloat(data.light_intensity) || 0,
        battery_level: parseFloat(data.battery_level) || 100,
        timestamp: new Date().toLocaleTimeString()
      });
      
      setConnectionStatus('Connected ✓');
      setLastUpdate(new Date().toLocaleString());
    } catch (error) {
      console.error('Error fetching sensor data:', error);
      console.error('API_URL:', API_URL);
      setConnectionStatus('Disconnected - Check API');
    }
  };

  // Send device control commands
  const sendCommand = async (command) => {
    setLoading(true);
    setCommandStatus('Sending...');
    try {
      const response = await axios.post(COMMANDS_API, {
        command: command,
        device_id: 'sensor1',
        timestamp: new Date().toISOString()
      });
      
      const result = JSON.parse(response.data.body);
      setCommandStatus(`✅ ${result.message}`);
      
      // Refresh sensor data after command
      setTimeout(() => {
        fetchSensorData();
        setCommandStatus('');
      }, 1000);
    } catch (error) {
      console.error('Error sending command:', error);
      setCommandStatus('❌ Command failed');
    }
    setLoading(false);
  };

  // Poll sensor data every 3 seconds
  useEffect(() => {
    fetchSensorData();
    const interval = setInterval(fetchSensorData, 3000);
    return () => clearInterval(interval);
  }, []);

  // Add to history only when sensor values actually change
  useEffect(() => {
    setHistory(prev => {
      const latest = prev[0];
      if (latest) {
        const valuesChanged = 
          latest.soil_moisture !== sensorData.soil_moisture ||
          latest.temperature !== sensorData.temperature ||
          latest.humidity !== sensorData.humidity ||
          latest.light_intensity !== sensorData.light_intensity ||
          latest.battery_level !== sensorData.battery_level;
        
        if (valuesChanged) {
          return [
            { ...sensorData, id: Date.now() },
            ...prev.slice(0, 9)
          ];
        }
      } else {
        return [
          { ...sensorData, id: Date.now() },
          ...prev.slice(0, 9)
        ];
      }
      return prev;
    });

    const newAlerts = [];
    if (sensorData.soil_moisture < 30) {
      newAlerts.push({ type: 'warning', msg: 'Low soil moisture!' });
    }
    if (sensorData.temperature > 30) {
      newAlerts.push({ type: 'warning', msg: 'High temperature!' });
    }
    if (sensorData.battery_level < 20) {
      newAlerts.push({ type: 'critical', msg: 'Low battery!' });
    }
    setAlerts(newAlerts);
  }, [sensorData]);

  const getHealthStatus = () => {
    if (sensorData.soil_moisture < 30 || sensorData.temperature > 30 || sensorData.battery_level < 20) {
      return { status: 'Critical', color: 'bg-red-500', text: 'text-red-700' };
    }
    if (sensorData.soil_moisture < 40 || sensorData.humidity < 50) {
      return { status: 'Warning', color: 'bg-yellow-500', text: 'text-yellow-700' };
    }
    return { status: 'Healthy', color: 'bg-green-500', text: 'text-green-700' };
  };

  const health = getHealthStatus();

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-green-900 to-slate-900 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <Cloud className="w-10 h-10 text-green-400" />
              <h1 className="text-4xl font-bold text-white">PlantX IoT Dashboard</h1>
            </div>
            <div className={`px-4 py-2 rounded-lg font-bold ${health.color} text-white`}>
              {health.status}
            </div>
          </div>
          <p className="text-gray-400">Real-time plant monitoring with AWS DynamoDB</p>
        </div>

        {/* Alerts */}
        {alerts.length > 0 && (
          <div className="mb-6 space-y-2">
            {alerts.map((alert, i) => (
              <div key={i} className="bg-red-500/20 border border-red-500 text-red-300 px-4 py-3 rounded-lg flex items-center gap-2">
                <AlertCircle className="w-5 h-5" />
                {alert.msg}
              </div>
            ))}
          </div>
        )}

        {/* Main Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
          {/* Soil Moisture */}
          <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6 hover:bg-white/20 transition">
            <div className="flex items-center justify-between mb-4">
              <Droplets className="w-6 h-6 text-blue-400" />
              <span className="text-2xl font-bold text-white">{sensorData.soil_moisture.toFixed(1)}%</span>
            </div>
            <p className="text-gray-400 text-sm">Soil Moisture</p>
            <div className="mt-2 bg-gray-700 rounded-full h-2 overflow-hidden">
              <div className="bg-blue-500 h-full transition-all" style={{ width: `${Math.min(100, sensorData.soil_moisture)}%` }} />
            </div>
          </div>

          {/* Temperature */}
          <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6 hover:bg-white/20 transition">
            <div className="flex items-center justify-between mb-4">
              <Thermometer className="w-6 h-6 text-red-400" />
              <span className="text-2xl font-bold text-white">{sensorData.temperature.toFixed(1)}°C</span>
            </div>
            <p className="text-gray-400 text-sm">Temperature</p>
            <div className="mt-2 text-xs text-gray-400">Optimal: 18-28°C</div>
          </div>

          {/* Humidity */}
          <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6 hover:bg-white/20 transition">
            <div className="flex items-center justify-between mb-4">
              <Wind className="w-6 h-6 text-cyan-400" />
              <span className="text-2xl font-bold text-white">{sensorData.humidity.toFixed(1)}%</span>
            </div>
            <p className="text-gray-400 text-sm">Humidity</p>
            <div className="mt-2 bg-gray-700 rounded-full h-2 overflow-hidden">
              <div className="bg-cyan-500 h-full transition-all" style={{ width: `${Math.min(100, sensorData.humidity)}%` }} />
            </div>
          </div>

          {/* Light */}
          <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6 hover:bg-white/20 transition">
            <div className="flex items-center justify-between mb-4">
              <Zap className="w-6 h-6 text-yellow-400" />
              <span className="text-2xl font-bold text-white">{sensorData.light_intensity.toFixed(1)}%</span>
            </div>
            <p className="text-gray-400 text-sm">Light Intensity</p>
            <div className="mt-2 bg-gray-700 rounded-full h-2 overflow-hidden">
              <div className="bg-yellow-500 h-full transition-all" style={{ width: `${Math.min(100, sensorData.light_intensity)}%` }} />
            </div>
          </div>

          {/* Battery */}
          <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6 hover:bg-white/20 transition">
            <div className="flex items-center justify-between mb-4">
              <Zap className="w-6 h-6 text-green-400" />
              <span className="text-2xl font-bold text-white">{sensorData.battery_level.toFixed(1)}%</span>
            </div>
            <p className="text-gray-400 text-sm">Battery Level</p>
            <div className="mt-2 bg-gray-700 rounded-full h-2 overflow-hidden">
              <div className={`h-full transition-all ${sensorData.battery_level > 50 ? 'bg-green-500' : 'bg-yellow-500'}`} style={{ width: `${Math.min(100, sensorData.battery_level)}%` }} />
            </div>
          </div>
        </div>

        {/* Control Panel */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          <div className="lg:col-span-2 bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6">
            <h2 className="text-xl font-bold text-white mb-4">Device Control</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button
                onClick={() => sendCommand('water')}
                disabled={loading}
                className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white py-3 px-4 rounded-lg font-semibold transition flex items-center justify-center gap-2"
              >
                <Droplets className="w-5 h-5" />
                Water Plant
              </button>
              <button
                onClick={() => sendCommand('light_on')}
                disabled={loading}
                className="bg-yellow-600 hover:bg-yellow-700 disabled:opacity-50 text-white py-3 px-4 rounded-lg font-semibold transition flex items-center justify-center gap-2"
              >
                <Zap className="w-5 h-5" />
                Grow Light ON
              </button>
              <button
                onClick={() => sendCommand('reset')}
                disabled={loading}
                className="bg-purple-600 hover:bg-purple-700 disabled:opacity-50 text-white py-3 px-4 rounded-lg font-semibold transition flex items-center justify-center gap-2"
              >
                <Send className="w-5 h-5" />
                Reset Sensor
              </button>
            </div>
            {/* Auto Watering Toggle */}
            <div className="mt-6 p-4 bg-white/5 border border-white/10 rounded-lg">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-white font-semibold mb-1">Auto Watering</p>
                  <p className="text-gray-400 text-sm">Automatically water when soil moisture is low</p>
                </div>
                <button
                  onClick={() => setAutoWateringEnabled(!autoWateringEnabled)}
                  className={`relative w-16 h-8 rounded-full transition-colors ${
                    autoWateringEnabled ? 'bg-green-600' : 'bg-gray-600'
                  }`}
                >
                  <div
                    className={`absolute top-1 w-6 h-6 bg-white rounded-full transition-transform ${
                      autoWateringEnabled ? 'translate-x-9' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>
              <p className={`mt-2 text-sm font-semibold ${autoWateringEnabled ? 'text-green-400' : 'text-gray-400'}`}>
                {autoWateringEnabled ? '✓ Auto watering active' : '○ Auto watering inactive'}
              </p>
            </div>

            {commandStatus && (
              <div className="mt-4 p-3 bg-green-500/20 border border-green-500 text-green-300 rounded-lg">
                {commandStatus}
              </div>
            )}
          </div>

          {/* System Info */}
          <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6">
            <h3 className="text-lg font-bold text-white mb-4">System Info</h3>
            <div className="space-y-3 text-sm">
              <div>
                <p className="text-gray-400">Last Update</p>
                <p className="text-white font-mono text-xs">{sensorData.timestamp}</p>
              </div>
              <div>
                <p className="text-gray-400">Device ID</p>
                <p className="text-white font-mono">sensor1</p>
              </div>
              <div>
                <p className="text-gray-400">Data Timestamp</p>
                <p className="text-white font-mono text-xs">{lastUpdate || 'Loading...'}</p>
              </div>
              <div>
                <p className="text-gray-400">Connection Status</p>
                <p className={connectionStatus === 'Connected ✓' ? 'text-green-400' : 'text-red-400'}>
                  {connectionStatus}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* History */}
        <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6">
          <h2 className="text-xl font-bold text-white mb-4">Recent Readings</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-gray-400 border-b border-gray-700">
                  <th className="text-left py-2 px-4">Time</th>
                  <th className="text-center py-2 px-4">Moisture</th>
                  <th className="text-center py-2 px-4">Temp</th>
                  <th className="text-center py-2 px-4">Humidity</th>
                  <th className="text-center py-2 px-4">Light</th>
                  <th className="text-center py-2 px-4">Battery</th>
                </tr>
              </thead>
              <tbody>
                {history.map((reading) => (
                  <tr key={reading.id} className="border-b border-gray-700/50 hover:bg-white/5">
                    <td className="py-2 px-4 text-gray-300">{reading.timestamp}</td>
                    <td className="text-center py-2 px-4 text-blue-400">{reading.soil_moisture.toFixed(1)}%</td>
                    <td className="text-center py-2 px-4 text-red-400">{reading.temperature.toFixed(1)}°C</td>
                    <td className="text-center py-2 px-4 text-cyan-400">{reading.humidity.toFixed(1)}%</td>
                    <td className="text-center py-2 px-4 text-yellow-400">{reading.light_intensity.toFixed(1)}%</td>
                    <td className="text-center py-2 px-4 text-green-400">{reading.battery_level.toFixed(1)}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}