import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '2m', target: 300 },
    { duration: '2m', target: 400 },
    { duration: '2m', target: 0 },
  ],
  noConnectionReuse: false,
};

export default function () {
  // Use the environment variable passed from Bash
  const url = `${__ENV.BASE_URL || 'http://127.0.0.1:8001'}/io_bound/0.05`;

  const res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'latency < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}