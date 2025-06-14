import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import "dayjs/locale/fr";

dayjs.locale(navigator.language || navigator.languages[0]);
dayjs.extend(relativeTime);

export default dayjs;