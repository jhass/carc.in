import { EmbeddedRecordsMixin } from '@ember-data/serializer/rest';
import { ActiveModelSerializer } from 'active-model-adapter';

export default ActiveModelSerializer.extend(EmbeddedRecordsMixin, {
  isNewSerializerAPI: true,
  attrs: {
    run: {deserialize: 'records', serialize: false}
  }
});
