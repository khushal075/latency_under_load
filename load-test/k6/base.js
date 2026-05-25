import http from 'k6/http';
import {check, sleep} from 'k6';

export function runTest(url){
    const res = http.get(url);

    check(res, {
        'status is 200': (r) => r.status === 200,
    });
    sleep(0.1);
}