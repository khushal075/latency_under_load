export const baseConfig = {
    stages: [
        { duration: "30s", target: 50 },   // ramp up
        { duration: "1m", target: 100 },   // sustain
        { duration: "30s", target: 0 },    // ramp down
    ],
    thresholds : {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.5']
    }
};