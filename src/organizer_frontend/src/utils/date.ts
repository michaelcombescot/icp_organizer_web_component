import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import "dayjs/locale/fr";

dayjs.locale(navigator.language || navigator.languages[0]);
dayjs.extend(relativeTime);

export default dayjs;

export function stringToEpoch(str: string): bigint {
    return str != "" ? BigInt(dayjs(str).valueOf()) : BigInt(0)
}

export function remainingTimeFromEpoch(dateEpoch: bigint): string {
    return dayjs(Number(dateEpoch)).fromNow()
}

export function stringDateFromEpoch(dateEpoch: bigint): string {
        return dayjs(Number(dateEpoch)).format("DD/MM/YYYY HH:mm")
    }