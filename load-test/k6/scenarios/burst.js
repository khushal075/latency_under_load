import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '5s', target: 200 },
    { duration: '20s', target: 200 },
    { duration: '5s', target: 0 },
  ],
  noConnectionReuse: false,
};

export default function () {
  // Use the environment variable BASE_URL, or fallback to 8001 if it's missing
  const url = `${__ENV.BASE_URL || 'http://127.0.0.1:8001'}/io_bound/0.05`;

  const res = http.get(url);

  check(res, {
    'is status 200': (r) => r.status === 200,
  });

  sleep(0.1);
}