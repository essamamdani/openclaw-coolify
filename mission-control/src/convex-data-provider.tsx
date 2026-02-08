import React from "react";
import { useQuery, useMutation } from "convex/react";
import { api } from "../convex/_generated/api";
import { MCDataContext } from "./demo-provider";
import type { MCData } from "./demo-provider";
import type { TaskStatus, TaskPriority } from "./types";
import type { Id } from "../convex/_generated/dataModel";

/**
 * ConvexDataProvider — wraps Convex hooks into the unified MCData context.
 * Used when VITE_CONVEX_URL is set.
 */
export function ConvexDataProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const agents = useQuery(api.agents.list) ?? [];
  const tasksByStatus = useQuery(api.tasks.listByStatus) ?? {
    inbox: [],
    assigned: [],
    in_progress: [],
    review: [],
    done: [],
  };
  const counts = useQuery(api.tasks.countByStatus) ?? {
    queue: 0,
    total: 0,
  };
  const activities = useQuery(api.activities.listRecent, { limit: 50 }) ?? [];

  const createTaskMut = useMutation(api.tasks.create);
  const updateStatusMut = useMutation(api.tasks.updateStatus);
  const assignTaskMut = useMutation(api.tasks.assign);

  const createTask = (args: {
    title: string;
    description: string;
    priority: TaskPriority;
    createdBy: string;
    tags?: string[];
  }) => {
    createTaskMut(args);
  };

  const moveTask = (taskId: Id<"tasks">, status: TaskStatus) => {
    updateStatusMut({ taskId, status, agentId: "human" });
  };

  const assignTask = (taskId: Id<"tasks">, agentId: string) => {
    assignTaskMut({ taskId, assignedTo: agentId, agentId: "human" });
  };

  const value: MCData = {
    agents,
    tasksByStatus,
    counts,
    activities,
    createTask,
    moveTask,
    assignTask,
    isDemoMode: false,
  };

  return (
    <MCDataContext.Provider value={value}>{children}</MCDataContext.Provider>
  );
}
