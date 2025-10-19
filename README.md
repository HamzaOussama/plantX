# plantX 🌱

An IoT-based plant monitoring and automation system using AWS services and React for real-time plant health tracking.

## Features

- **Live Sensor Monitoring**: Real-time soil moisture, temperature, humidity, light intensity, and battery level
- **MQTT Integration**: AWS IoT Core for device communication
- **Device Control**: Water plant, grow light, and sensor reset commands
- **Auto-watering Toggle**: UI for automatic watering control
- **Alert System**: Notifications for critical conditions
- **Beautiful Dashboard**: Responsive React UI with Tailwind CSS
- **Cloud Storage**: DynamoDB for secure sensor data storage
- **REST API**: API Gateway endpoints for dashboard integration

## Tech Stack

**Backend:**
- AWS IoT Core (MQTT)
- AWS Lambda (Python)
- AWS DynamoDB (Data storage)
- AWS API Gateway (REST endpoints)
- AWS IAM (Security & permissions)
- AWS KMS (Encryption)

**Frontend:**
- React.js
- Tailwind CSS
- Axios (API calls)
- Lucide React (Icons)

## Project Architecture
```
IoT Devices → AWS IoT Core → Lambda → DynamoDB
                                ↓
                            API Gateway
                                ↓
                          React Dashboard
```

## Getting Started

### Prerequisites
- Node.js (v14+)
- npm or yarn
- AWS Account with IoT Core, Lambda, DynamoDB, and API Gateway

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/SmartPlant-Guardian.git
cd SmartPlant-Guardian
```

2. Install dependencies:
```bash
npm install
```

3. Configure API endpoints in `src/Dashboard.js`:
```javascript
const API_URL = 'your-api-gateway-url/dev/';
const COMMANDS_API = 'your-api-gateway-url/dev/commands';
```

4. Start the development server:
```bash
npm start
```

5. Open [http://localhost:3000](http://localhost:3000)

## Dashboard Metrics

- **Soil Moisture**: Current soil moisture percentage
- **Temperature**: Environmental temperature in Celsius
- **Humidity**: Air humidity percentage
- **Light Intensity**: Light level percentage
- **Battery Level**: Device battery percentage

## Device Controls

- **Water Plant**: Sends watering command
- **Grow Light ON**: Activates grow light
- **Reset Sensor**: Resets sensor readings
- **Auto Watering**: Toggle for automatic watering

## AWS Setup

### Required Services

1. **AWS IoT Core**
   - Create a Thing for your device
   - Generate certificates
   - Create IoT Rules for MQTT topics

2. **DynamoDB**
   - Table: `plantx-sensor-readings-dev`
   - Partition Key: `device_id`
   - Sort Key: `timestamp`

3. **Lambda Functions**
   - `GetSensorData`: Fetch latest readings
   - `ControlPlantDevice`: Send device commands

4. **API Gateway**
   - Endpoint: `/` (GET) → GetSensorData Lambda
   - Endpoint: `/commands` (POST) → ControlPlantDevice Lambda

5. **IAM Roles**
   - Lambda execution role with DynamoDB and KMS permissions

## Data Flow

1. **Sensor Publishing**: IoT device publishes MQTT message
2. **IoT Rule Processing**: AWS IoT Rule routes message to DynamoDB
3. **Data Storage**: DynamoDB stores encrypted sensor data
4. **API Query**: React dashboard queries latest data via API Gateway
5. **Real-time Display**: Dashboard updates every 3 seconds
6. **Command Execution**: Dashboard sends commands back to device

## File Structure
```
SmartPlant-Guardian/
├── public/
├── src/
│   ├── Dashboard.js       # Main React component
│   ├── App.js
│   ├── index.css
│   └── index.js
├── package.json
└── README.md
```

## Future Enhancements

- [ ] Multi-device support
- [ ] Data visualization with charts
- [ ] User authentication
- [ ] Mobile app version
- [ ] Alexa skill integration
- [ ] Email/SMS notifications
- [ ] Deployment to production

## Troubleshooting

**Dashboard shows zeros:**
- Check API Gateway URL is correct
- Verify Lambda has DynamoDB permissions
- Ensure KMS key is accessible

**MQTT messages not reaching DynamoDB:**
- Verify IoT Rule is enabled
- Check IoT Core certificates
- Review CloudWatch logs

**CORS errors:**
- Ensure API Gateway has CORS enabled
- Check Access-Control-Allow-Origin header

## License

MIT License - feel free to use this project for personal or commercial purposes.

## Author

Oussama HAMZA

## Contact

- GitHub: [[@yourusername](https://github.com/yourusername)](https://github.com/HamzaOussama)
- Email: oussamahamza.1002@gmail.com

---

Built with ❤️ using AWS and React
