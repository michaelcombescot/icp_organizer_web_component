import './App';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import "dayjs/locale/fr";
import './index.scss';
import { isAuthenticated } from './components/auth/auth';
import { StoreGlobal } from './modules/todo/stores/storeGlobal';
import { getLoadingComponent } from './components/loading';


(async () => {
    dayjs.locale(navigator.language || navigator.languages[0]);
    dayjs.extend(relativeTime);

    if ( isAuthenticated ) {
        getLoadingComponent().wrapAsync(async () => {
            await StoreGlobal.loadUserData();
        })
    }
})();