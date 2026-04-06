import { SetMetadata } from '@nestjs/common';
import { ActivityActionType } from 'src/common/constants/activity-log.constants';

export const LOG_ACTIVITY_KEY = 'log_activity';
export const LogActivity = (action: ActivityActionType) => SetMetadata(LOG_ACTIVITY_KEY, action);
