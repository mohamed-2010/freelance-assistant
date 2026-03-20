import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/clients/clients_list_screen.dart';
import '../features/clients/client_detail_screen.dart';
import '../features/clients/client_form_screen.dart';
import '../features/clients/account_statement_screen.dart';
import '../features/projects/project_detail_screen.dart';
import '../features/projects/project_form_screen.dart';
import '../features/tasks/task_form_screen.dart';
import '../features/payments/payments_list_screen.dart';
import '../features/payments/payment_form_screen.dart';
import '../features/invoices/invoices_list_screen.dart';
import '../features/invoices/invoice_create_screen.dart';
import '../features/invoices/invoice_detail_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/clients',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ClientsListScreen(),
          ),
        ),
        GoRoute(
          path: '/invoices',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InvoicesListScreen(),
          ),
        ),
        GoRoute(
          path: '/payments',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PaymentsListScreen(),
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    // Detail & Form routes (outside shell for full-screen navigation)
    GoRoute(
      path: '/clients/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ClientDetailScreen(
        clientId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/clients/:id/statement',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccountStatementScreen(
        clientId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/clients-form',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final clientId = state.uri.queryParameters['id'];
        return ClientFormScreen(clientId: clientId);
      },
    ),
    GoRoute(
      path: '/projects/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ProjectDetailScreen(
        projectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/projects-form',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final projectId = state.uri.queryParameters['id'];
        final clientId = state.uri.queryParameters['clientId'];
        return ProjectFormScreen(
          projectId: projectId,
          clientId: clientId,
        );
      },
    ),
    GoRoute(
      path: '/tasks-form',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final taskId = state.uri.queryParameters['id'];
        final projectId = state.uri.queryParameters['projectId'];
        return TaskFormScreen(
          taskId: taskId,
          projectId: projectId,
        );
      },
    ),
    // Payment routes
    GoRoute(
      path: '/payments/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final clientId = state.uri.queryParameters['clientId'];
        return PaymentFormScreen(clientId: clientId);
      },
    ),
    GoRoute(
      path: '/payments/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final paymentId = state.uri.queryParameters['id'];
        final clientId = state.uri.queryParameters['clientId'];
        return PaymentFormScreen(clientId: clientId, paymentId: paymentId);
      },
    ),
    // Invoice routes
    GoRoute(
      path: '/invoices/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => InvoiceDetailScreen(
        invoiceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/invoices/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final clientId = state.uri.queryParameters['clientId'];
        return InvoiceCreateScreen(clientId: clientId);
      },
    ),
  ],
);
