import {runTest} from '../base.js';
import {baseConfig} from '../config.js';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8001';

export const options = baseConfig;

export default function() {
    const delay = 0.05; // 50 ms DB delay
    runTest(`${BASE_URL}/connection_hold/${delay}`);
}