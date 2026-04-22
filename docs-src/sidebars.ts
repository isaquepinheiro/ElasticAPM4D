import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Projects',
      items: [{ type: 'link', label: 'ElasticAPM4D', href: '/elasticapm4d/' }],
    },
  ],
  elasticapm4dSidebar: [
    {
      type: 'category',
      label: 'ElasticAPM4D',
      link: { type: 'doc', id: 'elasticapm4d/index' },
      items: [
        'elasticapm4d/introduction',
        {
          type: 'category',
          label: 'Getting Started',
          items: [
            'elasticapm4d/getting-started/quickstart',
          ],
        },
        {
          type: 'category',
          label: 'Guides',
          items: [
            'elasticapm4d/guides/manual-instrumentation',
            'elasticapm4d/guides/auto-instrumentation',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: [
            'elasticapm4d/reference/configuration',
          ],
        },
        {
          type: 'category',
          label: 'Troubleshooting',
          items: [
            'elasticapm4d/troubleshooting/common-errors',
          ],
        },
        {
          type: 'category',
          label: 'Advanced (Developer)',
          items: [
            'elasticapm4d/architecture/overview',
            'elasticapm4d/architecture/runtime-flow',
            'elasticapm4d/reference/api',
            'elasticapm4d/guides/stacktrace-providers',
            'elasticapm4d/guides/custom-transport',
            'elasticapm4d/guides/local-setup',
            'elasticapm4d/tests/overview',
          ],
        },
      ],
    },
  ],
};

export default sidebars;
