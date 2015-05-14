export default DS.ActiveModelSerializer.extend(DS.EmbeddedRecordsMixin, {
  attrs: {
    run: {deserialize: 'records', serialize: false}
  }
});
