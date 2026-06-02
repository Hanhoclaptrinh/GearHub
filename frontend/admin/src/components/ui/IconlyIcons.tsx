import React from 'react';
import {
  Activity as IconlyActivity,
  AddUser,
  ArrowDown as IconlyArrowDown,
  ArrowLeft as IconlyArrowLeft,
  ArrowRight as IconlyArrowRight,
  ArrowRightSquare,
  ArrowUp as IconlyArrowUp,
  Bag2,
  Buy,
  Calendar as IconlyCalendar,
  Call,
  Category,
  Chat,
  ChevronDown as IconlyChevronDown,
  ChevronLeft as IconlyChevronLeft,
  ChevronRight as IconlyChevronRight,
  ChevronUp as IconlyChevronUp,
  CloseSquare,
  Danger,
  Delete,
  Discovery,
  Discount,
  Document,
  Download as IconlyDownload,
  Edit as IconlyEdit,
  Filter as IconlyFilter,
  Filter2,
  Folder,
  Graph,
  Heart,
  Home as IconlyHome,
  Image as IconlyImage,
  Image2,
  InfoCircle,
  Location,
  Lock as IconlyLock,
  Logout,
  Message,
  MoreCircle,
  MoreSquare,
  Paper,
  Password,
  People,
  Plus as IconlyPlus,
  Scan,
  Search as IconlySearch,
  Send as IconlySend,
  Setting,
  ShieldDone,
  ShieldFail,
  Show,
  Star as IconlyStar,
  Swap,
  Ticket as IconlyTicket,
  TickSquare,
  TimeCircle,
  Upload,
  User as IconlyUser,
  Wallet,
  Work,
} from 'react-iconly';
import type { IconProps as ReactIconlyProps } from 'react-iconly';

type IconlyComponent = React.FC<ReactIconlyProps>;

export type IconlyAdapterProps = Omit<React.HTMLAttributes<HTMLSpanElement>, 'children'> & {
  color?: string;
  fill?: string;
  size?: number | string;
  strokeWidth?: number;
  title?: string;
};

export type LucideIcon = React.FC<IconlyAdapterProps>;

const normalizeSize = (size?: number | string) => {
  if (typeof size === 'number') return size;
  if (typeof size === 'string') {
    const parsed = Number.parseInt(size, 10);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return 20;
};

const createIcon = (Icon: IconlyComponent, set: ReactIconlyProps['set'] = 'curved'): LucideIcon => {
  const AdapterIcon: LucideIcon = ({
    className,
    color = 'currentColor',
    fill: _fill,
    size,
    strokeWidth: _strokeWidth,
    style,
    title,
    role,
    ...props
  }) => {
    void _fill;
    void _strokeWidth;

    return (
      <span
        {...props}
        aria-label={title}
        className={[
          'inline-flex shrink-0 items-center justify-center leading-none [&_svg]:h-full [&_svg]:w-full',
          className,
        ].filter(Boolean).join(' ')}
        role={title ? 'img' : role}
        style={style}
        title={title}
      >
        <Icon primaryColor={color} secondaryColor={color} set={set} size={normalizeSize(size)} />
      </span>
    );
  };

  return AdapterIcon;
};

export const Activity = createIcon(IconlyActivity);
export const AlertCircle = createIcon(Danger);
export const AlertTriangle = createIcon(Danger);
export const ArrowDown = createIcon(IconlyArrowDown);
export const ArrowLeft = createIcon(IconlyArrowLeft);
export const ArrowRight = createIcon(IconlyArrowRight);
export const ArrowUp = createIcon(IconlyArrowUp);
export const ArrowUpRight = createIcon(ArrowRightSquare);
export const ArrowUpDown = createIcon(Swap);
export const Archive = createIcon(Folder);
export const Barcode = createIcon(Scan);
export const Bell = createIcon(IconlyActivity);
export const Box = createIcon(Bag2);
export const Briefcase = createIcon(Work);
export const Calendar = createIcon(IconlyCalendar);
export const CalendarDays = createIcon(IconlyCalendar);
export const Check = createIcon(TickSquare);
export const CheckCheck = createIcon(TickSquare);
export const CheckCircle2 = createIcon(TickSquare);
export const ChevronDown = createIcon(IconlyChevronDown);
export const ChevronLeft = createIcon(IconlyChevronLeft);
export const ChevronRight = createIcon(IconlyChevronRight);
export const ChevronUp = createIcon(IconlyChevronUp);
export const Clock = createIcon(TimeCircle);
export const Clock3 = createIcon(TimeCircle);
export const CreditCard = createIcon(Wallet);
export const Download = createIcon(IconlyDownload);
export const DollarSign = createIcon(Wallet);
export const Edit = createIcon(IconlyEdit);
export const Edit2 = createIcon(IconlyEdit);
export const Edit3 = createIcon(IconlyEdit);
export const EllipsisVertical = createIcon(MoreSquare);
export const ExternalLink = createIcon(ArrowRightSquare);
export const Eye = createIcon(Show);
export const EyeOff = createIcon(ShieldFail);
export const FileSpreadsheet = createIcon(Document);
export const FileText = createIcon(Document);
export const Filter = createIcon(IconlyFilter);
export const FolderTree = createIcon(Folder);
export const Gem = createIcon(IconlyStar);
export const Globe = createIcon(Discovery);
export const Hash = createIcon(Paper);
export const History = createIcon(TimeCircle);
export const Home = createIcon(IconlyHome);
export const Image = createIcon(IconlyImage);
export const ImageIcon = createIcon(IconlyImage);
export const ImagePlus = createIcon(Image2);
export const Info = createIcon(InfoCircle);
export const KeyRound = createIcon(Password);
export const Laptop = createIcon(Work);
export const Layers = createIcon(Category);
export const LayoutDashboard = createIcon(Category);
export const Loader2 = createIcon(TimeCircle);
export const Lock = createIcon(IconlyLock);
export const LogOut = createIcon(Logout);
export const Mail = createIcon(Message);
export const MailSearch = createIcon(Message);
export const MapPin = createIcon(Location);
export const Menu = createIcon(MoreSquare);
export const MessageSquare = createIcon(Chat);
export const MessageSquareText = createIcon(Message);
export const MoreHorizontal = createIcon(MoreCircle);
export const NotebookText = createIcon(Document);
export const Package = createIcon(Bag2);
export const Percent = createIcon(Discount);
export const Phone = createIcon(Call);
export const Plus = createIcon(IconlyPlus);
export const Quote = createIcon(Message);
export const Radio = createIcon(IconlyActivity);
export const ReceiptText = createIcon(Document);
export const RefreshCcw = createIcon(Swap);
export const RotateCcw = createIcon(Swap);
export const Save = createIcon(Paper);
export const Search = createIcon(IconlySearch);
export const SendIcon = createIcon(IconlySend);
export const Send2 = createIcon(IconlySend);
export const SendSquare = createIcon(IconlySend);
export const Send = createIcon(IconlySend);
export const SendHorizontal = createIcon(IconlySend);
export const Settings2 = createIcon(Setting);
export const Shield = createIcon(ShieldDone);
export const ShieldAlert = createIcon(ShieldFail);
export const ShieldCheck = createIcon(ShieldDone);
export const ShoppingBag = createIcon(Buy);
export const ShoppingCart = createIcon(Buy);
export const SlidersHorizontal = createIcon(Filter2);
export const Smile = createIcon(Heart);
export const Sparkles = createIcon(IconlyStar);
export const Star = createIcon(IconlyStar);
export const Tag = createIcon(IconlyTicket);
export const Ticket = createIcon(IconlyTicket);
export const ToggleRight = createIcon(Swap);
export const TrendingUp = createIcon(Graph);
export const Trash2 = createIcon(Delete);
export const UploadCloud = createIcon(Upload);
export const User = createIcon(IconlyUser);
export const UserCheck = createIcon(AddUser);
export const UserIcon = createIcon(IconlyUser);
export const UserPlus = createIcon(AddUser);
export const UserRound = createIcon(IconlyUser);
export const UserRoundCheck = createIcon(AddUser);
export const UserX = createIcon(ShieldFail);
export const Users = createIcon(People);
export const Wand2 = createIcon(IconlyEdit);
export const Warehouse = createIcon(Work);
export const X = createIcon(CloseSquare);
export const XCircle = createIcon(CloseSquare);
export const ZoomIn = createIcon(Scan);
