import './App';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import "dayjs/locale/fr";
import './index.scss';
import { isAuthenticated } from './auth/auth';
import { StoreGlobal } from './modules/todo/stores/storeGlobal';


(async () => {
    dayjs.locale(navigator.language || navigator.languages[0]);
    dayjs.extend(relativeTime);
})();