import * as React from 'react';

export interface PfDailyQuestRowProps {
  /** Emoji icon displayed in the icon box */
  icon: string;
  label: string;
  /** Time string, e.g. "8:00 AM" or "In 2 hrs" */
  time: string;
  /** XP reward value */
  xp: number;
  /** Completed — strikes through label, turns icon box mint */
  done?: boolean;
  /** Overdue — turns time label poppy-red, prefixes "Due " */
  due?: boolean;
  /** Optional trailing widget */
  trailing?: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PfDailyQuestRow(props: PfDailyQuestRowProps): React.ReactElement;
