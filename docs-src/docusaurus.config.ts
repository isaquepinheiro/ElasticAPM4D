import type { Config } from '@docusaurus/types';

const config: Config = {
  title: 'Project Documentation Portal',
  url: 'https://example.com',
  baseUrl: '/',
  favicon: 'img/favicon.ico',
  organizationName: 'isaquepinheiro',
  projectName: 'ElasticAPM4D',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.ts'),
        },
        blog: false,
        pages: false,
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'Docs Portal',
      items: [
        {
          label: 'Projects',
          position: 'left',
          items: [{ to: '/elasticapm4d/', label: 'ElasticAPM4D' }],
        },
      ],
    },
  },
};

export default config;
