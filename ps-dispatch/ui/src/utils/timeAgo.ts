const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

function getFormattedDate(date: Date, preformattedDate: string | false = false, hideYear = false): string {
  const day = date.getDate();
  const month = MONTH_NAMES[date.getMonth()];
  const year = date.getFullYear();
  const hours = date.getHours();
  const minutes = date.getMinutes().toString().padStart(2, '0');

  if (preformattedDate) {
    return `${preformattedDate} at ${hours}:${minutes}`;
  }

  if (hideYear) {
    return `${day}. ${month} at ${hours}:${minutes}`;
  }

  return `${day}. ${month} ${year}. at ${hours}:${minutes}`;
}

export function timeAgo(dateParam: Date | string | number | null | undefined): string {
  if (!dateParam) {
    return 'Unknown';
  }

  let date: Date;
  try {
    date = dateParam instanceof Date ? dateParam : new Date(dateParam);
  } catch {
    return 'Invalid date';
  }

  if (Number.isNaN(date.getTime())) {
    return 'Invalid date';
  }

  const DAY_IN_MS = 86_400_000;
  const today = new Date();
  const yesterday = new Date(today.getTime() - DAY_IN_MS);
  const seconds = Math.round((today.getTime() - date.getTime()) / 1000);
  const minutes = Math.round(seconds / 60);
  const isToday = today.toDateString() === date.toDateString();
  const isYesterday = yesterday.toDateString() === date.toDateString();
  const isThisYear = today.getFullYear() === date.getFullYear();

  if (seconds < 5) {
    return 'Just Now';
  }

  if (seconds < 60) {
    return `${seconds} Seconds ago`;
  }

  if (seconds < 90) {
    return 'A minute ago';
  }

  if (minutes < 60) {
    return `${minutes} Minutes ago`;
  }

  if (isToday) {
    return getFormattedDate(date, 'Today');
  }

  if (isYesterday) {
    return getFormattedDate(date, 'Yesterday');
  }

  if (isThisYear) {
    return getFormattedDate(date, false, true);
  }

  return getFormattedDate(date);
}
