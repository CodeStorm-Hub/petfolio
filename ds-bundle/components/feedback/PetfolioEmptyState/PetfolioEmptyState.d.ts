import * as React from 'react';

export interface PetfolioEmptyStateProps {
  /** Material icon name or emoji string rendered at 48px */
  icon: React.ReactNode;
  title: string;
  subtitle?: string;
  /** Optional CTA button */
  action?: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PetfolioEmptyState(props: PetfolioEmptyStateProps): React.ReactElement;
