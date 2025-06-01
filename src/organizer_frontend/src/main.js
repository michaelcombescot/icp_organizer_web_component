import App from './App';
import { DB } from './db/db';
import './index.scss';


await DB.init();

const app = new App();
