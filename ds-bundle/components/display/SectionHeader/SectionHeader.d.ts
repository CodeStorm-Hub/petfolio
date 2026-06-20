import * as React from 'react';

export interface SectionHeaderProps {
  /** Rendered uppercase. 11px Inter Bold tracked. */
  label: string;
  /** Optional trailing action (button, link, etc.) */
  action?: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}

export declare function SectionHeader(props: SectionHeaderProps): React.ReactElement;
