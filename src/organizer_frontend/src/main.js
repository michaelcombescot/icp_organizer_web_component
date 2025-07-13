import './App';
import { DB } from './db/db';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import "dayjs/locale/fr";
import './index.scss';
import { todoStore } from './modules/todo/models/store';


(async () => {
    await DB.init();
    dayjs.locale(navigator.language || navigator.languages[0]);
    dayjs.extend(relativeTime);

    todoStore.loadStore();
})();